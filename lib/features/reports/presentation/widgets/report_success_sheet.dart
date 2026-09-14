import 'package:flutter/material.dart';
import '../../../../app/theme/index.dart';
import '../../../../core/animations/motion.dart';
import '../../../../shared/widgets/basic_widgets.dart';

/// Confirmation bottom sheet shown after a report is submitted successfully,
/// shared by the manual wizard (`create_report_page.dart`) and the
/// voice-driven flow (`ai_report_page.dart`) so both end in the same place.
class ReportSuccessSheet extends StatelessWidget {
  final String reportCode;
  final VoidCallback onViewTracking;
  final VoidCallback onBackToMap;

  const ReportSuccessSheet({
    super.key,
    required this.reportCode,
    required this.onViewTracking,
    required this.onBackToMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSuccessCheck(size: 80, color: AppColors.resolvedGreen, icon: Icons.check),
          const SizedBox(height: AppSpacing.lg),
          Text('Reporte enviado', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text('Tu comunidad ya fue notificada.', style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ID del reporte', style: AppTextStyles.bodySmallSecondary),
                    Text(reportCode,
                        style: AppTextStyles.labelMedium.copyWith(fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estado', style: AppTextStyles.bodySmallSecondary),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
                      ),
                      child: Text('Recibido', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryBlue)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Ver seguimiento',
            onPressed: onViewTracking,
            isExpanded: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppOutlinedButton(
            label: 'Volver al mapa',
            onPressed: onBackToMap,
            isExpanded: true,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
