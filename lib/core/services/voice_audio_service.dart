import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:flutter_sound/flutter_sound.dart';

/// Thin wrapper around device microphone capture and raw-PCM streaming
/// playback, kept separate from [GeminiLiveService] so audio-hardware
/// plumbing never mixes with the WebSocket protocol logic.
///
/// Gemini Live expects mic input as PCM16 mono @16kHz and sends its own
/// speech back as PCM16 mono @24kHz. Capture uses flutter_sound's streaming
/// recorder. Playback uses flutter_pcm_sound instead of flutter_sound's own
/// player: flutter_sound's `startPlayerFromStream`/`feedUint8FromStream`
/// path has a reproducible native SIGSEGV on Android (null-pointer inside
/// `FlautoPlayerEngine$FeedThread` -> `AudioTrack.write`) that persists even
/// with the recorder fully closed, on the latest published flutter_sound
/// version — so it isn't safe to drive raw PCM playback with it here.
class VoiceAudioService {
  static const int inputSampleRate = 16000;
  static const int outputSampleRate = 24000;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  /// Persistent across pause/resume cycles (unlike the recorder session
  /// itself), so callers can subscribe once via [micChunks] and keep
  /// receiving chunks across every duck cycle without resubscribing.
  final StreamController<Uint8List> _micController = StreamController<Uint8List>.broadcast();

  bool _isRecorderOpen = false;
  bool _isPcmSoundSetUp = false;
  bool _isPlaybackActive = false;
  Future<void>? _startingPlayback;
  Future<void> _captureOp = Future.value();

  /// Queued as int16 samples (not raw bytes) since flutter_pcm_sound's
  /// `feed()` takes samples directly — converting once here avoids
  /// re-parsing byte offsets inside the feed callback.
  final List<int> _playbackQueue = [];

  Stream<Uint8List> get micChunks => _micController.stream;

  Future<void> startCapture() => _openAndStartRecorder();

  Future<void> _openAndStartRecorder() async {
    if (!_isRecorderOpen) {
      await _recorder.openRecorder();
      _isRecorderOpen = true;
    }
    await _recorder.startRecorder(
      toStream: _micController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: inputSampleRate,
    );
  }

  /// Fully stops *and closes* the recorder so the native `AudioRecord` is
  /// released while the model is speaking. Calls are serialized through
  /// [_captureOp] since Gemini's event stream can re-enter the caller before
  /// a prior pause/resume finishes.
  Future<void> pauseCapture() {
    _captureOp = _captureOp.then((_) async {
      if (!_isRecorderOpen) return;
      try {
        await _recorder.stopRecorder();
      } catch (_) {}
      try {
        await _recorder.closeRecorder();
      } catch (_) {}
      _isRecorderOpen = false;
    });
    return _captureOp;
  }

  Future<void> resumeCapture() {
    _captureOp = _captureOp.then((_) async {
      if (_isRecorderOpen) return;
      await _openAndStartRecorder();
    });
    return _captureOp;
  }

  Future<void> stopCapture() async {
    await pauseCapture();
  }

  /// Idempotent playback start — concurrent callers all await the same
  /// in-flight setup instead of triggering their own.
  Future<void> ensurePlaybackStarted() async {
    if (_isPlaybackActive) return;
    if (_startingPlayback != null) {
      await _startingPlayback;
      return;
    }
    final starting = _doStartPlayback();
    _startingPlayback = starting;
    try {
      await starting;
    } finally {
      _startingPlayback = null;
    }
  }

  Future<void> _doStartPlayback() async {
    if (!_isPcmSoundSetUp) {
      await FlutterPcmSound.setup(sampleRate: outputSampleRate, channelCount: 1);
      await FlutterPcmSound.setFeedThreshold(outputSampleRate ~/ 10);
      FlutterPcmSound.setFeedCallback(_onFeed);
      _isPcmSoundSetUp = true;
    }
    FlutterPcmSound.start();
    _isPlaybackActive = true;
  }

  /// Pull callback fired by the native engine when its buffer is running
  /// low. Feeds whatever is queued; if nothing is queued yet (network is
  /// slower than playback) it simply feeds nothing and waits for the next
  /// callback rather than blocking or feeding silence.
  void _onFeed(int remainingFrames) {
    if (_playbackQueue.isEmpty) return;
    final count = remainingFrames < _playbackQueue.length ? remainingFrames : _playbackQueue.length;
    if (count <= 0) return;
    final chunk = _playbackQueue.sublist(0, count);
    _playbackQueue.removeRange(0, count);
    FlutterPcmSound.feed(PcmArrayInt16.fromList(chunk));
  }

  void feed(Uint8List pcmChunk) {
    if (!_isPlaybackActive) return;
    final byteData = ByteData.sublistView(pcmChunk);
    for (int i = 0; i + 1 < pcmChunk.length; i += 2) {
      _playbackQueue.add(byteData.getInt16(i, Endian.little));
    }
  }

  /// Drops any buffered-but-unplayed audio — used on Gemini Live's
  /// `interrupted` signal so a barge-in doesn't leave a tail of stale audio
  /// playing after the user starts talking. Only queued-but-not-yet-fed
  /// samples can be dropped this way; flutter_pcm_sound has no hard native
  /// flush, so a few already-native-buffered milliseconds may still play.
  Future<void> stopPlaybackAndFlush() async {
    _isPlaybackActive = false;
    _playbackQueue.clear();
  }

  Future<void> dispose() async {
    await pauseCapture();
    await stopPlaybackAndFlush();
    if (_isPcmSoundSetUp) {
      try {
        await FlutterPcmSound.release();
      } catch (_) {}
      _isPcmSoundSetUp = false;
    }
    await _micController.close();
  }
}
