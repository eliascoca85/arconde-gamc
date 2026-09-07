import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../app/theme/index.dart';
import '../../../../core/services/settings_store.dart';
import '../../../../shared/widgets/basic_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
  bool? _notifyReportUpdates;
  PermissionStatus? _locationStatus;
  PermissionStatus? _microphoneStatus;
  PermissionStatus? _cameraStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SettingsStore.loadNotifyReportUpdates().then((value) {
      if (!mounted) return;
      setState(() => _notifyReportUpdates = value);
    });
    _refreshPermissionStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissionStatuses();
  }

  Future<void> _refreshPermissionStatuses() async {
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
    } catch (_) {}
  }

  Future<void> _togglePermission(Permission permission, PermissionStatus? current) async {
    if (current == null) return;
    try {
      if (current.isGranted || current.isPermanentlyDenied) {
        await openAppSettings();
      } else {
        await permission.request();
      }
    } catch (_) {}
    await _refreshPermissionStatuses();
  }

  Future<void> _setNotifyReportUpdates(bool value) async {
    setState(() => _notifyReportUpdates = value);
    await SettingsStore.setNotifyReportUpdates(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Configuración', style: AppTextStyles.titleLarge),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _sectionTitle('Notificaciones'),
          const SizedBox(height: AppSpacing.md),
          _card([
            SwitchListTile(
              value: _notifyReportUpdates ?? true,
              onChanged: _notifyReportUpdates == null ? null : _setNotifyReportUpdates,
              activeThumbColor: AppColors.secondaryTeal,
              title: Text('Alertas y actualizaciones', style: AppTextStyles.bodyLarge),
              subtitle: Text(
                'Avisos sobre el estado de tus reportes.',
                style: AppTextStyles.bodySmallSecondary,
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle('Permisos de la app'),
          const SizedBox(height: AppSpacing.md),
          _card([
            _permissionTile(
              icon: Icons.location_on_outlined,
              title: 'Ubicación',
              status: _locationStatus,
              onTap: () => _togglePermission(Permission.locationWhenInUse, _locationStatus),
              isLast: false,
            ),
            _permissionTile(
              icon: Icons.mic_none_outlined,
              title: 'Micrófono',
              status: _microphoneStatus,
              onTap: () => _togglePermission(Permission.microphone, _microphoneStatus),
              isLast: false,
            ),
            _permissionTile(
              icon: Icons.camera_alt_outlined,
              title: 'Cámara',
              status: _cameraStatus,
              onTap: () => _togglePermission(Permission.camera, _cameraStatus),
              isLast: true,
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'Si ya negaste un permiso, tocarlo te lleva a Ajustes del sistema para activarlo.',
              style: AppTextStyles.bodySmallTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: AppTextStyles.titleMedium);

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _permissionTile({
    required IconData icon,
    required String title,
    required PermissionStatus? status,
    required VoidCallback onTap,
    required bool isLast,
  }) {
    final granted = status?.isGranted ?? false;
    return ListTile(
      leading: AppIconBadge(
        icon: icon,
        gradient: granted ? AppColors.primaryGradient : AppColors.urgentGradient,
        size: 40,
        iconSize: AppSpacing.iconMd,
      ),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(
        status == null ? 'No disponible' : (granted ? 'Concedido' : 'No concedido'),
        style: AppTextStyles.bodySmallSecondary,
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: status == null ? null : onTap,
      shape: Border(
        bottom: isLast ? BorderSide.none : BorderSide(color: AppColors.divider, width: 0.5),
      ),
    );
  }
}
