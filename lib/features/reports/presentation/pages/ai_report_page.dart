import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../app/theme/index.dart';
import '../../../../core/animations/motion.dart';
import '../../../../core/config/env.dart';
import '../../../../core/network/gemini_live_service.dart';
import '../../../../core/network/nominatim_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/voice_audio_service.dart';
import '../../../../data/repositories/emergency_repository.dart';
import '../../../../mock/models.dart';
import '../../../../shared/widgets/basic_widgets.dart';
import '../widgets/report_success_sheet.dart';

enum _VoiceState {
  idle,
  requestingPermission,
  connecting,
  listening,
  modelSpeaking,
  submitting,
  success,
  error,
}

class _Transcript {
  final bool isUser;
  final String text;
  const _Transcript({required this.isUser, required this.text});
}

/// Voice-driven report flow: the user talks naturally with a Gemini Live
/// agent, which asks follow-up questions as needed and calls `submit_report`
/// once it has enough information. The manual 4-step wizard
/// ([AppRouter.createReport]) stays reachable from every state here as a
/// fallback — this screen must never be a dead end.
///
/// Photo evidence is out of scope for v1: a voice conversation has no camera
/// step, so reports created here never carry attachments.
class AiReportPage extends StatefulWidget {
  const AiReportPage({super.key});

  @override
  State<AiReportPage> createState() => _AiReportPageState();
}

class _AiReportPageState extends State<AiReportPage> {
  final _emergencyRepository = EmergencyRepository();
  final _voiceAudio = VoiceAudioService();
  GeminiLiveService? _gemini;
  StreamSubscription<GeminiLiveEvent>? _eventSubscription;
  StreamSubscription? _micSubscription;

  _VoiceState _state = _VoiceState.idle;
  String _errorMessage = '';
  double? _latitude;
  double? _longitude;
  String? _address;
  final List<_Transcript> _transcripts = [];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _micSubscription?.cancel();
    _voiceAudio.dispose();
    _gemini?.close();
    super.dispose();
  }

  Future<void> _start() async {
    if (!Env.hasGeminiApiKey) {
      setState(() {
        _state = _VoiceState.error;
        _errorMessage = 'El reporte por voz todavía no está configurado en esta app.';
      });
      return;
    }

    setState(() => _state = _VoiceState.requestingPermission);
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      setState(() {
        _state = _VoiceState.error;
        _errorMessage = 'Necesitamos acceso al micrófono para reportar por voz.';
      });
      return;
    }

    setState(() => _state = _VoiceState.connecting);

    final locationResult = await LocationService.getCurrentPositionResult();
    if (locationResult.status != LocationResultStatus.success || locationResult.position == null) {
      setState(() {
        _state = _VoiceState.error;
        _errorMessage = switch (locationResult.status) {
          LocationResultStatus.serviceDisabled => 'Activa la ubicación del dispositivo para poder reportar.',
          LocationResultStatus.permissionDenied => 'Necesitamos acceso a tu ubicación para reportar.',
          LocationResultStatus.permissionDeniedForever =>
            'El permiso de ubicación está bloqueado. Habilítalo desde los ajustes del sistema.',
          _ => 'No pudimos obtener tu ubicación. Intenta nuevamente.',
        };
      });
      return;
    }

    _latitude = locationResult.position!.latitude;
    _longitude = locationResult.position!.longitude;
    unawaited(
      NominatimService.reverseGeocode(_latitude!, _longitude!).then((address) {
        _address = address;
      }),
    );

    await _connectGemini();
  }

  Future<void> _connectGemini() async {
    final gemini = GeminiLiveService(apiKey: Env.geminiApiKey);
    _gemini = gemini;
    _eventSubscription = gemini.events.listen(_onGeminiEvent);
    await gemini.connect();
  }

  Future<void> _onGeminiEvent(GeminiLiveEvent event) async {
    if (!mounted) return;
    switch (event) {
      case GeminiLiveReady():
        _micSubscription = _voiceAudio.micChunks.listen((chunk) {
          _gemini?.sendAudioChunk(chunk);
        });
        await _voiceAudio.startCapture();
        setState(() => _state = _VoiceState.listening);
      case GeminiLiveModelAudioChunk(:final pcm):
        if (_state != _VoiceState.modelSpeaking) {
          // Mic must be fully paused before the player starts — flutter_sound
          // crashes natively on Android if both stream at once (see
          // VoiceAudioService.pauseCapture).
          await _voiceAudio.pauseCapture();
          setState(() => _state = _VoiceState.modelSpeaking);
        }
        await _voiceAudio.ensurePlaybackStarted();
        _voiceAudio.feed(pcm);
      case GeminiLiveInterrupted():
        await _voiceAudio.stopPlaybackAndFlush();
        await _voiceAudio.resumeCapture();
        setState(() => _state = _VoiceState.listening);
      case GeminiLiveTurnComplete():
        if (_state == _VoiceState.modelSpeaking) {
          await _voiceAudio.stopPlaybackAndFlush();
          await _voiceAudio.resumeCapture();
          setState(() => _state = _VoiceState.listening);
        }
      case GeminiLiveTranscript(:final isUser, :final text):
        setState(() => _transcripts.add(_Transcript(isUser: isUser, text: text)));
      case GeminiLiveToolCall(:final id, :final category, :final description):
        await _submitReport(callId: id, category: category, description: description);
      case GeminiLiveError(:final message):
        setState(() {
          _state = _VoiceState.error;
          _errorMessage = 'Se perdió la conexión con el asistente. Intenta nuevamente.';
        });
        debugPrint('GeminiLiveError: $message');
      case GeminiLiveClosed():
        if (_state != _VoiceState.success && _state != _VoiceState.submitting) {
          setState(() {
            _state = _VoiceState.error;
            _errorMessage = 'Se cerró la conexión con el asistente.';
          });
        }
    }
  }

  Future<void> _submitReport({
    required String callId,
    required String category,
    required String description,
  }) async {
    setState(() => _state = _VoiceState.submitting);
    await _voiceAudio.stopCapture();

    try {
      final combinedDescription = '[$category] $description';
      final matchedType = IncidentType.values.firstWhere(
        (type) => type.label == category,
        orElse: () => IncidentType.other,
      );
      final emergency = await _emergencyRepository.report(
        description: combinedDescription,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address ?? '',
        category: matchedType,
      );
      _gemini?.sendToolResponse(callId, success: true);

      if (!mounted) return;
      setState(() => _state = _VoiceState.success);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ReportSuccessSheet(
          reportCode: emergency.emergencyCode,
          onViewTracking: () {
            Navigator.pop(context);
            context.go('/reports/my');
          },
          onBackToMap: () {
            Navigator.pop(context);
            context.go('/');
          },
        ),
      );
    } catch (_) {
      _gemini?.sendToolResponse(callId, success: false);
      if (!mounted) return;
      setState(() {
        _state = _VoiceState.error;
        _errorMessage = 'No se pudo enviar el reporte. Intenta nuevamente.';
      });
    }
  }

  void _retry() {
    setState(() {
      _errorMessage = '';
      _transcripts.clear();
    });
    _start();
  }

  void _goManual() {
    context.push(AppRouter.createReport);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Reportar con voz', style: AppTextStyles.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _state == _VoiceState.error ? _buildError() : _buildVoiceFlow(),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic_off, size: AppSpacing.iconXl * 1.5, color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('No se pudo iniciar el reporte por voz', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(_errorMessage, style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Reintentar', icon: Icons.refresh, onPressed: _retry),
          const SizedBox(height: AppSpacing.md),
          AppOutlinedButton(label: 'Reportar manualmente', icon: Icons.edit_note, onPressed: _goManual),
        ],
      ),
    );
  }

  Widget _buildVoiceFlow() {
    return Column(
      children: [
        Expanded(
          child: _transcripts.isEmpty
              ? Center(child: _buildStatusIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _transcripts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _transcripts.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(child: _buildStatusIndicator()),
                      );
                    }
                    final entry = _transcripts[index];
                    return Align(
                      alignment: entry.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: entry.isUser ? AppColors.primaryBlue.withValues(alpha: 0.15) : AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                        ),
                        child: Text(entry.text, style: AppTextStyles.bodyMedium),
                      ).immersiveEntrance(),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
          child: AppTextButton(
            label: 'Reportar manualmente',
            icon: Icons.edit_note,
            onPressed: _goManual,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    switch (_state) {
      case _VoiceState.idle:
      case _VoiceState.requestingPermission:
      case _VoiceState.connecting:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoadingIndicator(size: 40),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _state == _VoiceState.requestingPermission
                  ? 'Solicitando acceso al micrófono…'
                  : 'Conectando con el asistente…',
              style: AppTextStyles.bodyMediumSecondary,
            ),
          ],
        );
      case _VoiceState.listening:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: AppColors.urgentRed, shape: BoxShape.circle),
              child: const Icon(Icons.mic, color: Colors.white, size: 40),
            ).pulseGlow(),
            const SizedBox(height: AppSpacing.lg),
            Text('Te escuchamos, contanos qué pasó', style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
          ],
        );
      case _VoiceState.modelSpeaking:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 40),
            ).pulseGlow(),
            const SizedBox(height: AppSpacing.lg),
            Text('El asistente está hablando…', style: AppTextStyles.bodyMediumSecondary),
          ],
        );
      case _VoiceState.submitting:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoadingIndicator(size: 40),
            const SizedBox(height: AppSpacing.lg),
            Text('Enviando tu reporte…', style: AppTextStyles.bodyMediumSecondary),
          ],
        );
      case _VoiceState.success:
        return const AppSuccessCheck(size: 64, color: AppColors.resolvedGreen, icon: Icons.check);
      case _VoiceState.error:
        return const SizedBox.shrink();
    }
  }
}
