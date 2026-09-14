import 'package:flutter/material.dart';
import '../../../../app/theme/index.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/basic_widgets.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Acerca de', style: AppTextStyles.titleLarge),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Column(
              children: [
                AppIconBadge(
                  icon: Icons.shield_outlined,
                  gradient: AppColors.accentGradient,
                  size: 72,
                  iconSize: 34,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(AppConstants.appName, style: AppTextStyles.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text('Versión 1.0.0', style: AppTextStyles.bodyMediumSecondary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(color: AppColors.borderPrimary, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appTagline, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Arconte conecta a la ciudadanía con las autoridades para reportar incidentes de seguridad en tiempo real: robos, accidentes, personas sospechosas y más, con evidencia y ubicación exacta.',
                  style: AppTextStyles.bodyMediumSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              '© ${DateTime.now().year} Arconte',
              style: AppTextStyles.bodySmallTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
