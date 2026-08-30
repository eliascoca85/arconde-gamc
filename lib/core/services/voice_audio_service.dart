import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

/// Thin wrapper around device microphone capture and raw-PCM streaming
/// playback, kept separate from [GeminiLiveService] so audio-hardware
/// plumbing never mixes with the WebSocket protocol logic.
///
/// Gemini Live expects mic input as PCM16 mono @16kHz and sends its own
/// speech back as PCM16 mono @24kHz — both handled here via flutter_sound's
/// streaming recorder/player, since simpler file/URL players can't consume
/// raw PCM chunks in real time.
class VoiceAudioService {
  static const int inputSampleRate = 16000;
  static const int outputSampleRate = 24000;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  /// Persistent across pause/resume cycles (unlike the recorder session
  /// itself), so callers can subscribe once via [micChunks] and keep
  /// receiving chunks across every duck cycle without resubscribing.
  final StreamController<Uint8List> _micController = StreamController<Uint8List>.broadcast();

  bool _isRecorderOpen = false;
  bool _isPlayerOpen = false;
  bool _isPlaybackActive = false;
  Future<void>? _startingPlayback;
  Future<void> _captureOp = Future.value();

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

  /// Fully stops *and closes* the recorder (not just `stopRecorder()`) so the
  /// native `AudioRecord` is completely released before the player starts —
  /// on Android, flutter_sound crashes the whole process with a native
  /// SIGSEGV in `AudioTrack::releaseBuffer` when the mic and speaker engines
  /// run at the same time (a known, unresolved upstream bug). A lighter
  /// `pauseRecorder()`/`resumeRecorder()` was tried first and did not stop
  /// the crash, which means it doesn't release the underlying hardware
  /// resource — closing is the only way that reliably does.
  ///
  /// Calls are serialized through [_captureOp] since Gemini's event stream
  /// can re-enter the caller before a prior pause/resume finishes.
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

  /// Idempotent, re-entrancy-safe playback start. Gemini's audio chunks can
  /// arrive back-to-back before the first `startPlayerFromStream()` call
  /// finishes (event handling is async, so the stream listener doesn't wait
  /// for one call to complete before delivering the next), and calling
  /// `startPlayerFromStream` twice concurrently on the same player crashes
  /// natively (two competing `AudioTrack` feed threads). Concurrent callers
  /// here all await the same in-flight start instead of triggering their own.
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
    if (!_isPlayerOpen) {
      await _player.openPlayer();
      _isPlayerOpen = true;
    }
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      interleaved: true,
      numChannels: 1,
      sampleRate: outputSampleRate,
      bufferSize: 8192,
    );
    _isPlaybackActive = true;
  }

  void feed(Uint8List pcmChunk) {
    if (_isPlaybackActive) {
      _player.feedUint8FromStream(pcmChunk);
    }
  }

  /// Stops playback and drops any buffered-but-unplayed audio — used on
  /// Gemini Live's `interrupted` signal so a barge-in doesn't leave a tail
  /// of stale audio playing after the user starts talking.
  Future<void> stopPlaybackAndFlush() async {
    _isPlaybackActive = false;
    if (_isPlayerOpen) {
      await _player.stopPlayer();
    }
  }

  Future<void> dispose() async {
    await pauseCapture();
    await stopPlaybackAndFlush();
    if (_isPlayerOpen) {
      await _player.closePlayer();
      _isPlayerOpen = false;
    }
    await _micController.close();
  }
}
