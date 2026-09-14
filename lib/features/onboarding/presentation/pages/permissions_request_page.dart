import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../app/theme/index.dart';
import '../../../../core/animations/motion.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../shared/widgets/basic_widgets.dart';

/// Pantalla de onboarding de permisos: se muestra una sola vez en la vida de
/// la instalación, justo después de que carga la primera vista de la app
/// (antes de decidir si se muestra el login o la app), para dejar que el
/// usuario active de una vez los permisos que Arconte usa.
///
/// Independiente de esta pantalla, cada función que de verdad necesita un
/// permiso lo sigue pidiendo puntualmente si todavía no fue concedido (mic
/// en el reporte por voz, ubicación al geolocalizar, cámara/galería al
/// adjuntar evidencia) — ver [PermissionService].
class PermissionsRequestPage extends StatefulWidget {
  /// Se llama cuando el usuario ya resolvió el onboarding (concedió, negó o
  /// lo saltó) y la app puede continuar con su flujo normal.
  final VoidCallback onDone;

  const PermissionsRequestPage({super.key, required this.onDone});

  @override
  State<PermissionsRequestPage> createState() => _PermissionsRequestPageState();
}

enum _PendingAction { continueAction, skip }

class _PermissionsRequestPageState extends State<PermissionsRequestPage> with WidgetsBindingObserver {
  _PendingAction? _pendingAction;
  PermissionStatus? _locationStatus;
  PermissionStatus? _microphoneStatus;
  PermissionStatus? _cameraStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // El usuario pudo haber ido a Ajustes del sistema (desde un toggle) y
    // vuelto — al retomar la app, se refleja el estado real más reciente.
    if (state == AppLifecycleState.resumed) _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    try {
      final results = await Future.wait([
        Permission.locationWhenInUse.status,
        Permission.microphone.status,
        Permission.camera.status,
      ]);
      if (!mounted) return;
      setState(() {
        _locationStatus = results[0];
        _microphoneStatus = results[1];
        _cameraStatus = results[2];
      });
    } catch (_) {
      // Plataforma sin soporte (p.ej. algunos navegadores): los toggles
      // quedan deshabilitados en vez de romper la pantalla.
    }
  }

  Future<void> _togglePermission(Permission permission, PermissionStatus? current) async {
    if (current == null) return;
    try {
      if (current.isGranted || current.isPermanentlyDenied) {
        // Una app no puede revocarse un permiso a sí misma — la única forma
        // de "apagarlo" es llevar al usuario a Ajustes del sistema. Lo mismo
        // aplica si ya fue denegado permanentemente: pedirlo de nuevo no
        // muestra ningún diálogo.
        await openAppSettings();
      } else {
        await permission.request();
      }
    } catch (_) {}
    await _refreshStatuses();
  }

  Future<void> _finish(_PendingAction action) async {
    setState(() => _pendingAction = action);
    await PermissionService.markInitialOnboardingSkipped();
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Align(
            alignment: const Alignment(0, 0.25),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIconBadge(
                      icon: Icons.shield_outlined,
                      gradient: AppColors.accentGradient,
                      size: 72,
                      iconSize: 34,
                    ).immersiveEntrance(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Permisos que usa Arconte',
                      style: AppTextStyles.headlineSmall,
                      textAlign: TextAlign.center,
                    ).immersiveEntrance(delay: 80.ms),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Actívalos ahora o cuando los necesites al reportar.',
                      style: AppTextStyles.bodyMediumSecondary,
                      textAlign: TextAlign.center,
                    ).immersiveEntrance(delay: 120.ms),
                    const SizedBox(height: AppSpacing.xl),
                    _PermissionItem(
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.primaryBlue,
                      title: 'Ubicación',
                      description: 'Para marcar automáticamente dónde ocurre el incidente que reportas.',
                      granted: _locationStatus?.isGranted ?? false,
                      onChanged: _locationStatus == null
                          ? null
                          : (_) => _togglePermission(Permission.locationWhenInUse, _locationStatus),
                    ).staggerChild(0),
                    const SizedBox(height: AppSpacing.md),
                    _PermissionItem(
                      icon: Icons.mic_none_outlined,
                      iconColor: AppColors.secondaryTeal,
                      title: 'Micrófono',
                      description: 'Para poder reportar hablando con el asistente de voz.',
                      granted: _microphoneStatus?.isGranted ?? false,
                      onChanged: _microphoneStatus == null
                          ? null
                          : (_) => _togglePermission(Permission.microphone, _microphoneStatus),
                    ).staggerChild(1),
                    const SizedBox(height: AppSpacing.md),
                    _PermissionItem(
                      icon: Icons.camera_alt_outlined,
                      iconColor: AppColors.moderateOrange,
                      title: 'Cámara',
                      description: 'Para adjuntar fotos o video como evidencia de tu reporte.',
                      granted: _cameraStatus?.isGranted ?? false,
                      onChanged: _cameraStatus == null
                          ? null
                          : (_) => _togglePermission(Permission.camera, _cameraStatus),
                    ).staggerChild(2),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Continuar',
                      icon: Icons.arrow_forward,
                      isLoading: _pendingAction == _PendingAction.continueAction,
                      onPressed: _pendingAction == null ? () => _finish(_PendingAction.continueAction) : null,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextButton(
                      label: 'Ahora no',
                      onPressed: _pendingAction == null ? () => _finish(_PendingAction.skip) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool granted;
  final ValueChanged<bool>? onChanged;

  const _PermissionItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.granted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: AppSpacing.iconMd),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmallSecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(value: granted, onChanged: onChanged),
        ],
      ),
    );
  }
}
