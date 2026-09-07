import 'package:flutter/material.dart';
import '../../../../app/theme/index.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/settings_events.dart';
import '../../../../core/services/settings_store.dart';
import '../../../../shared/widgets/basic_widgets.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _clearing = false;

  Future<void> _confirmClearLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg)),
        title: Text('Borrar datos locales', style: AppTextStyles.headlineSmall),
        content: Text(
          'Se borrarán tus zonas favoritas y preferencias guardadas en este dispositivo. Tu cuenta y tus reportes no se ven afectados.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: AppTextStyles.labelMedium),
          ),
          AppButton(
            label: 'Borrar',
            isExpanded: false,
            backgroundColor: AppColors.error,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _clearing = true);
    await SettingsStore.clearLocalData();
    SettingsEvents.notifyFavoriteZonesChanged();
    if (!mounted) return;
    setState(() => _clearing = false);
    context.showSuccessSnackBar('Datos locales borrados.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Privacidad', style: AppTextStyles.titleLarge),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _infoCard(
            icon: Icons.assignment_outlined,
            title: 'Tus reportes',
            body: 'La descripción, ubicación y evidencia que adjuntas a un reporte se envían a las autoridades competentes para su atención.',
          ),
          const SizedBox(height: AppSpacing.md),
          _infoCard(
            icon: Icons.location_on_outlined,
            title: 'Ubicación',
            body: 'Solo se usa para marcar dónde ocurre el incidente que reportas o para centrar el mapa en tu posición. No se comparte con otros usuarios.',
          ),
          const SizedBox(height: AppSpacing.md),
          _infoCard(
            icon: Icons.badge_outlined,
            title: 'Datos de tu cuenta',
            body: 'Tu nombre, teléfono y CI se usan únicamente para identificarte ante las autoridades en caso de que un reporte lo requiera.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Datos en este dispositivo', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(color: AppColors.borderPrimary, width: 0.5),
            ),
            child: ListTile(
              leading: AppIconBadge(
                icon: Icons.delete_outline,
                gradient: AppColors.urgentGradient,
                size: 40,
                iconSize: AppSpacing.iconMd,
              ),
              title: Text('Borrar datos guardados en este dispositivo', style: AppTextStyles.bodyLarge),
              subtitle: Text(
                'Zonas favoritas y preferencias locales.',
                style: AppTextStyles.bodySmallSecondary,
              ),
              trailing: _clearing
                  ? const SizedBox(width: 20, height: 20, child: AppLoadingIndicator(size: 20))
                  : Icon(Icons.chevron_right, color: AppColors.textTertiary),
              onTap: _clearing ? null : _confirmClearLocalData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String body}) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBadge(icon: icon, gradient: AppColors.primaryGradient, size: 40, iconSize: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: AppTextStyles.bodySmallSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
