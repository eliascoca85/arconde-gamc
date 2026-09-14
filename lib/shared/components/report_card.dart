import 'package:flutter/material.dart';
import '../../app/theme/index.dart';
import '../../core/animations/motion.dart';
import '../../core/utils/formatters.dart';
import '../../mock/models.dart';
import '../../shared/widgets/basic_widgets.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;
  final int index;

  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeIcon(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title, style: AppTextStyles.titleMedium),
                    Text(
                      Formatters.formatIncidentType(report.type.value),
                      style: AppTextStyles.bodySmallSecondary,
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            report.description,
            style: AppTextStyles.bodyMediumSecondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Flexible(child: _buildLocationInfo()),
              const Spacer(),
              _buildDateInfo(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTimelineProgress(),
        ],
      ),
    ).staggerChild(index);
  }

  Gradient get _typeGradient {
    if (report.type == IncidentType.medicalEmergency) return AppColors.resolvedGradient;
    if (report.type == IncidentType.fire || report.type == IncidentType.violence) return AppColors.urgentGradient;
    return AppColors.primaryGradient;
  }

  Widget _buildTypeIcon() {
    return AppIconBadge(icon: report.typeIcon, gradient: _typeGradient, size: 40, iconSize: 20);
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (report.status) {
      case ReportStatus.received:
        color = AppColors.primaryBlue;
        break;
      case ReportStatus.inReview:
        color = AppColors.moderateOrange;
        break;
      case ReportStatus.attended:
        color = AppColors.resolvedGreen;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        report.statusLabel,
        style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, size: AppSpacing.iconXs, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            report.location.zone,
            style: AppTextStyles.bodySmallSecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: AppSpacing.iconXs, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          Formatters.formatRelativeTime(report.createdAt),
          style: AppTextStyles.bodySmallSecondary,
        ),
      ],
    );
  }

  Widget _buildTimelineProgress() {
    final completedSteps = report.timeline.where((e) => e.isCompleted).length;
    final totalSteps = report.timeline.length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Progreso', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
            const Spacer(),
            Text('${(progress * 100).round()}%', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryBlue)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: report.timeline.map((event) {
            final isLast = report.timeline.last == event;
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: event.isCompleted ? event.color : AppColors.borderSecondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: event.isCurrent ? event.color : AppColors.borderSecondary,
                        width: event.isCurrent ? 2 : 0,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: event.isCompleted ? event.color : AppColors.borderSecondary,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class CategoryChip extends StatelessWidget {
  final IncidentCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: isSelected ? category.gradient : null,
          color: isSelected ? null : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          border: Border.all(
            color: isSelected ? category.color : AppColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: AppSpacing.iconLg,
              color: isSelected ? AppColors.textOnPrimary : category.color,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              category.title,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              category.description,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.textOnPrimary.withValues(alpha: 0.8) : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final IncidentStatus status;
  final bool showLabel;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.showLabel = true,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case IncidentStatus.urgent:
        color = AppColors.urgentRed;
        break;
      case IncidentStatus.moderate:
        color = AppColors.moderateOrange;
        break;
      case IncidentStatus.resolved:
        color = AppColors.resolvedGreen;
        break;
    }

    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(status.label, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class ReportStatusIndicator extends StatelessWidget {
  final ReportStatus status;
  final bool showLabel;

  const ReportStatusIndicator({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ReportStatus.received:
        color = AppColors.primaryBlue;
        break;
      case ReportStatus.inReview:
        color = AppColors.moderateOrange;
        break;
      case ReportStatus.attended:
        color = AppColors.resolvedGreen;
        break;
    }

    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(status.label, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
      );
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}