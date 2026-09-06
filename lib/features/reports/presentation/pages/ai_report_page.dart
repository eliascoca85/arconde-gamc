import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../app/theme/index.dart';
import '../../../../core/animations/motion.dart';
import '../../../../core/network/gemini_live_service.dart';
import '../../../../core/network/nominatim_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/voice_audio_service.dart';
import '../../../../data/repositories/emergency_repository.dart';
import '../../../../mock/mock_data.dart';
import '../../../../mock/models.dart';
import '../../../../shared/widgets/app_map.dart';
import '../../../../shared/widgets/basic_widgets.dart';
import '../widgets/evidence_step.dart';
import '../widgets/report_success_sheet.dart';

enum _VoiceState {
  idle,
  requestingPermission,
  connecting,
  listening,
  modelSpeaking,
  pickingLocation,
  reviewing,
  submitting,
  success,
  error,
}

const LatLng _defaultMapCenter = LatLng(-17.3895, -66.1568);

class _Transcript {
  final bool isUser;
  final String text;
  const _Transcript({required this.isUser, required this.text});
}

/// Voice-driven report flow: the user talks naturally with a Gemini Live
/// agent, which asks follow-up questions as needed (including whether the
/// citizen is at the incident location — if not, it opens a map mid-call via
/// [markLocationManuallyTool]) and calls [submitReportTool] once it has
/// enough information. That silently ends the voice call and opens an
/// editable review screen (category, description, location, photo evidence)
/// before the report is actually sent. The manual 4-step wizard
/// ([AppRouter.createReport]) stays reachable from every state here as a
/// fallback — this screen must never be a dead end.
class AiReportPage extends StatefulWidget {
  const AiReportPage({super.key});

  @override
  State<AiReportPage> createState() => _AiReportPageState();
}

class _AiReportPageState extends State<AiReportPage> {
  final _emergencyRepository = EmergencyRepository();
  final _voiceAudio = VoiceAudioService();
  final _descriptionController = TextEditingController();
  GeminiLiveService? _gemini;
  StreamSubscription<GeminiLiveEvent>? _eventSubscription;
  StreamSubscription? _micSubscription;

  _VoiceState _state = _VoiceState.idle;
  String _errorMessage = '';
  double? _latitude;
  double? _longitude;
  String? _address;
  final List<_Transcript> _transcripts = [];
  bool _showTranscript = false;

  // Ubicación conversacional: qué pantalla retomar y qué tool call responder
  // al confirmar un punto en el mapa (ver mark_location_manually).
  _VoiceState _pickLocationReturnTo = _VoiceState.listening;
  String? _pendingLocationCallId;
  LatLng? _pendingPickedLatLng;

  // Revisión previa al envío: valores editables poblados desde submit_report.
  IncidentType? _reviewCategory;
  String _reviewDescription = '';
  List<String> _evidencePaths = [];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _micSubscription?.cancel();
    _descriptionController.dispose();
    _voiceAudio.dispose();
    _gemini?.close();
    super.dispose();
  }

  Future<void> _start() async {
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
    final String token;
    try {
      token = await _emergencyRepository.fetchGeminiLiveToken();
    } catch (e) {
      debugPrint('AiReportPage: fetchGeminiLiveToken failed: $e');
      if (!mounted) return;
      setState(() {
        _state = _VoiceState.error;
        _errorMessage = 'No se pudo iniciar el asistente de voz. Intenta nuevamente.';
      });
      return;
    }

    final gemini = GeminiLiveService(ephemeralToken: token);
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
      case GeminiLiveToolCall(:final id, :final name, :final args):
        if (name == markLocationManuallyTool) {
          await _handleMarkLocationTool(id);
        } else if (name == submitReportTool) {
          await _handleSubmitReportTool(id, args);
        }
      case GeminiLiveError(:final message):
        setState(() {
          _state = _VoiceState.error;
          _errorMessage = 'Se perdió la conexión con el asistente. Intenta nuevamente.';
        });
        debugPrint('GeminiLiveError: $message');
      case GeminiLiveClosed():
        if (_state != _VoiceState.success &&
            _state != _VoiceState.submitting &&
            _state != _VoiceState.reviewing &&
            _state != _VoiceState.pickingLocation) {
          setState(() {
            _state = _VoiceState.error;
            _errorMessage = 'Se cerró la conexión con el asistente.';
          });
        }
    }
  }

  Future<void> _handleMarkLocationTool(String callId) async {
    await _voiceAudio.pauseCapture();
    if (!mounted) return;
    setState(() {
      _pendingLocationCallId = callId;
      _pickLocationReturnTo = _VoiceState.listening;
      _pendingPickedLatLng =
          _latitude != null && _longitude != null ? LatLng(_latitude!, _longitude!) : _defaultMapCenter;
      _state = _VoiceState.pickingLocation;
    });
  }

  Future<void> _handleSubmitReportTool(String callId, Map<String, dynamic> args) async {
    final category = args['category'] as String? ?? '';
    final description = args['description'] as String? ?? '';
    final matchedType = IncidentType.values.firstWhere(
      (type) => type.label == category,
      orElse: () => IncidentType.other,
    );

    await _voiceAudio.stopCapture();
    _gemini?.sendToolResponse(callId, submitReportTool, success: true);
    await _gemini?.close();
    _gemini = null;

    if (!mounted) return;
    _descriptionController.text = description;
    setState(() {
      _reviewCategory = matchedType;
      _reviewDescription = description;
      _state = _VoiceState.reviewing;
    });
  }

  void _goPickLocationFromReview() {
    setState(() {
      _pendingLocationCallId = null;
      _pickLocationReturnTo = _VoiceState.reviewing;
      _pendingPickedLatLng =
          _latitude != null && _longitude != null ? LatLng(_latitude!, _longitude!) : _defaultMapCenter;
      _state = _VoiceState.pickingLocation;
    });
  }

  Future<void> _confirmPickedLocation() async {
    final point = _pendingPickedLatLng;
    if (point == null) return;

    _latitude = point.latitude;
    _longitude = point.longitude;
    _address = await NominatimService.reverseGeocode(_latitude!, _longitude!);
    if (!mounted) return;

    if (_pickLocationReturnTo == _VoiceState.listening) {
      final callId = _pendingLocationCallId;
      _pendingLocationCallId = null;
      if (callId != null && callId.isNotEmpty) {
        _gemini?.sendToolResponse(callId, markLocationManuallyTool, success: true);
      }
      await _voiceAudio.resumeCapture();
      if (!mounted) return;
      setState(() => _state = _VoiceState.listening);
    } else {
      setState(() => _state = _VoiceState.reviewing);
    }
  }

  Future<void> _confirmAndSubmitReport() async {
    final category = _reviewCategory;
    if (category == null || _latitude == null || _longitude == null) return;

    setState(() => _state = _VoiceState.submitting);

    try {
      final combinedDescription = '[${category.label}] $_reviewDescription';
      final emergency = await _emergencyRepository.report(
        description: combinedDescription,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address ?? '',
        category: category,
      );

      final localEvidence = _evidencePaths.where((path) => !path.startsWith('http'));
      var failedEvidenceCount = 0;
      for (final path in localEvidence) {
        try {
          await _emergencyRepository.uploadEvidence(
            emergency.pkEmergency,
            File(path),
            fileType: inferEvidenceFileType(path),
          );
        } catch (e, st) {
          // Una evidencia fallida no debe bloquear la confirmación del
          // reporte, pero sí debe avisarse (antes fallaba en silencio).
          debugPrint('uploadEvidence falló para $path: $e\n$st');
          failedEvidenceCount++;
        }
      }

      if (!mounted) return;
      setState(() => _state = _VoiceState.success);
      if (failedEvidenceCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failedEvidenceCount == 1
                  ? 'El reporte se envió, pero no se pudo adjuntar 1 evidencia.'
                  : 'El reporte se envió, pero no se pudieron adjuntar $failedEvidenceCount evidencias.',
            ),
          ),
        );
      }
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
      if (!mounted) return;
      setState(() {
        _state = _VoiceState.error;
        _errorMessage = 'No se pudo enviar el reporte. Intenta nuevamente.';
      });
    }
  }

  void _retryVoiceFromReview() {
    setState(() {
      _reviewCategory = null;
      _reviewDescription = '';
      _evidencePaths = [];
      _transcripts.clear();
      _descriptionController.clear();
      _state = _VoiceState.connecting;
    });
    _connectGemini();
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
        actions: [
          if (_state != _VoiceState.error && _transcripts.isNotEmpty)
            IconButton(
              tooltip: _showTranscript ? 'Ocultar conversación' : 'Ver conversación en texto',
              icon: Icon(_showTranscript ? Icons.subtitles : Icons.subtitles_outlined),
              onPressed: () => setState(() => _showTranscript = !_showTranscript),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _VoiceState.error:
        return _buildError();
      case _VoiceState.pickingLocation:
        return _buildPickingLocation();
      case _VoiceState.reviewing:
        return _buildReviewing();
      default:
        return _buildVoiceFlow();
    }
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
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIndicator(),
                if (_transcripts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _buildLiveCaption(),
                ],
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: _showTranscript ? _buildTranscriptPanel() : const SizedBox(width: double.infinity),
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

  Widget _buildPickingLocation() {
    final initial = _pendingPickedLatLng ?? _defaultMapCenter;
    final userLocation = _latitude != null && _longitude != null ? LatLng(_latitude!, _longitude!) : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Text(
            'Marca en el mapa el lugar donde ocurrió el incidente',
            style: AppTextStyles.bodyMediumSecondary,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppMapPicker(
            initialPosition: initial,
            userLocation: userLocation,
            onLocationSelected: (point) => setState(() => _pendingPickedLatLng = point),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              AppButton(
                label: 'Usar esta ubicación',
                icon: Icons.check,
                onPressed: _confirmPickedLocation,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextButton(
                label: 'Reportar manualmente',
                icon: Icons.edit_note,
                onPressed: _goManual,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewing() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.fact_check_outlined, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Revisa que todo esté correcto antes de enviar tu reporte.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ).staggerChild(0),
          const SizedBox(height: AppSpacing.xl),
          Text('Categoría', style: AppTextStyles.titleMedium).staggerChild(1),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: MockData.incidentCategories
                .map(
                  (category) => AppChip(
                    label: category.title,
                    icon: category.icon,
                    isSelected: _reviewCategory == category.type,
                    selectedColor: category.color.withValues(alpha: 0.22),
                    onTap: () => setState(() => _reviewCategory = category.type),
                  ),
                )
                .toList(),
          ).staggerChild(2),
          const SizedBox(height: AppSpacing.xl),
          Text('Descripción', style: AppTextStyles.titleMedium).staggerChild(3),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(hintText: 'Describe lo que pasó'),
            onChanged: (value) => _reviewDescription = value,
          ).staggerChild(4),
          const SizedBox(height: AppSpacing.xl),
          Text('Ubicación', style: AppTextStyles.titleMedium).staggerChild(5),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(color: AppColors.borderPrimary, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    (_address != null && _address!.isNotEmpty) ? _address! : 'Ubicación marcada en el mapa',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ).staggerChild(6),
          const SizedBox(height: AppSpacing.sm),
          AppTextButton(
            label: 'Cambiar ubicación en el mapa',
            icon: Icons.edit_location_alt_outlined,
            onPressed: _goPickLocationFromReview,
          ).staggerChild(7),
          const SizedBox(height: AppSpacing.lg),
          EvidenceStep(
            evidenceUrls: _evidencePaths,
            onEvidenceChanged: (urls) => setState(() => _evidencePaths = urls),
          ).staggerChild(8),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Enviar reporte',
            icon: Icons.send,
            onPressed: (_reviewCategory != null && _reviewDescription.trim().isNotEmpty)
                ? _confirmAndSubmitReport
                : null,
          ).staggerChild(9),
          const SizedBox(height: AppSpacing.md),
          AppOutlinedButton(
            label: 'Grabar de nuevo',
            icon: Icons.mic,
            onPressed: _retryVoiceFromReview,
          ).staggerChild(10),
          const SizedBox(height: AppSpacing.md),
          AppTextButton(
            label: 'Reportar manualmente',
            icon: Icons.edit_note,
            onPressed: _goManual,
          ).staggerChild(11),
        ],
      ),
    );
  }

  /// Only the most recent line, like a phone call's live captions — never a
  /// scrolling chat log. The full history still lives in `_transcripts` for
  /// the optional panel below; this is deliberately ephemeral so the screen
  /// keeps feeling like a conversation, not something to read.
  Widget _buildLiveCaption() {
    final last = _transcripts.last;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          last.text,
          key: ValueKey(_transcripts.length),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMediumSecondary.copyWith(
            fontStyle: last.isUser ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  /// Full conversation history, collapsed by default. Opt-in via the
  /// subtitles icon in the AppBar for anyone who'd rather read it back.
  Widget _buildTranscriptPanel() {
    return Container(
      height: 220,
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      ),
      child: ListView.builder(
        reverse: true,
        itemCount: _transcripts.length,
        itemBuilder: (context, index) {
          final entry = _transcripts[_transcripts.length - 1 - index];
          return Align(
            alignment: entry.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: entry.isUser ? AppColors.primaryBlue.withValues(alpha: 0.15) : AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              ),
              child: Text(entry.text, style: AppTextStyles.bodySmall),
            ),
          );
        },
      ),
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
      case _VoiceState.pickingLocation:
      case _VoiceState.reviewing:
        return const SizedBox.shrink();
    }
  }
}
