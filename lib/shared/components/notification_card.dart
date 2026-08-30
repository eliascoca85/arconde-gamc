import 'package:flutter/material.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/basic_widgets.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final int index;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.error, size: AppSpacing.iconLg),
      ),
      onDismissed: (_) => onDismiss?.call(),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ).pulseGlow(minScale: 1.0, maxScale: 1.6, duration: const Duration(milliseconds: 1200)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.message,
                    style: AppTextStyles.bodySmallSecondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        Formatters.formatRelativeTime(notification.timestamp),
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                      ),
                      if (notification.relatedReportId != null || notification.relatedIncidentId != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
                          ),
                          child: Text(
                            notification.relatedReportId != null ? 'Mi reporte' : 'Comunitario',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryBlue),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).staggerChild(index),
    );
  }

  Widget _buildIcon() {
    Gradient gradient;
    IconData icon;

    switch (notification.type) {
      case NotificationType.reportReceived:
        gradient = AppColors.primaryGradient;
        icon = Icons.mark_email_read_outlined;
        break;
      case NotificationType.reportInReview:
        gradient = AppColors.moderateGradient;
        icon = Icons.pending_outlined;
        break;
      case NotificationType.patrolAssigned:
        gradient = AppColors.primaryGradient;
        icon = Icons.local_police_outlined;
        break;
      case NotificationType.incidentResolved:
        gradient = AppColors.resolvedGradient;
        icon = Icons.check_circle_outline;
        break;
    }

    return AppIconBadge(icon: icon, gradient: gradient, size: 40, iconSize: 20);
  }
}