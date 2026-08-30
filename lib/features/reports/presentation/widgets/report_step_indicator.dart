import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';

class ReportStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;

  const ReportStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final labels = stepLabels ?? ['Tipo', 'Ubicación', 'Evidencia', 'Revisar'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;
              final isLast = index == totalSteps - 1;

              return Expanded(
                child: Row(
                  children: [
                    _buildStepCircle(index, isCompleted, isCurrent),
                    if (!isLast) _buildConnector(index, isCompleted),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(totalSteps, (index) {
              final isCurrent = index == currentStep;
              return Expanded(
                child: Text(
                  labels[index],
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isCurrent ? AppColors.secondaryTeal : AppColors.textTertiary,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
          ),
        ],
      ),
    ).immersiveEntrance(distance: -0.2, duration: const Duration(milliseconds: 400));
  }

  Widget _buildStepCircle(int index, bool isCompleted, bool isCurrent) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted || isCurrent ? AppColors.secondaryTeal : AppColors.surfaceSecondary,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? AppColors.secondaryTeal : AppColors.borderPrimary,
          width: isCurrent ? 3 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.secondaryTeal.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: isCompleted
          ? Icon(Icons.check, size: 18, color: AppColors.textOnPrimary)
          : Center(
              child: Text(
                '${index + 1}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isCurrent ? AppColors.textOnPrimary : AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    ).animate().scale(
          begin: Offset.zero,
          end: const Offset(1.0, 1.0),
          duration: Duration(milliseconds: 300 + index * 100),
          curve: Curves.elasticOut,
        );
  }

  Widget _buildConnector(int index, bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.secondaryTeal : AppColors.borderSecondary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}