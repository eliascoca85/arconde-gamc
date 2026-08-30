import 'package:flutter/material.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/basic_widgets.dart';

class IncidentHeader extends StatelessWidget {
  final Incident incident;

  const IncidentHeader({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: incident.statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
                border: Border.all(color: incident.statusColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: incident.statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    incident.statusLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: incident.statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _buildStatChip(Icons.visibility_outlined, incident.viewsCount.toString()),
            const SizedBox(width: AppSpacing.sm),
            _buildStatChip(Icons.thumb_up_outlined, incident.confirmationsCount.toString()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            AppIconBadge(
              icon: incident.typeIcon,
              gradient: _getTypeGradient(),
              size: 40,
              iconSize: AppSpacing.iconMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(incident.typeLabel, style: AppTextStyles.titleMedium),
                  Text(
                    'Reportado por ${incident.reporterName} · ${Formatters.formatRelativeTime(incident.createdAt)}',
                    style: AppTextStyles.bodySmallSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.iconXs, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Text(count, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Gradient _getTypeGradient() {
    switch (incident.type) {
      case IncidentType.medicalEmergency:
        return AppColors.resolvedGradient;
      case IncidentType.fire:
      case IncidentType.violence:
        return AppColors.urgentGradient;
      default:
        return AppColors.primaryGradient;
    }
  }
}

class IncidentTimeline extends StatelessWidget {
  final Incident incident;

  const IncidentTimeline({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    final timelineEvents = _getTimelineEvents();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seguimiento', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        ...timelineEvents.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          final isLast = index == timelineEvents.length - 1;

          return _TimelineItem(event: event, isLast: isLast).staggerChild(index);
        }),
      ],
    );
  }

  List<TimelineEvent> _getTimelineEvents() {
    return [
      TimelineEvent(
        id: 'tl_1',
        title: 'Recibido',
        description: '${Formatters.formatTime(incident.createdAt)} · Reporte registrado',
        timestamp: incident.createdAt,
        isCompleted: true,
        isCurrent: incident.status == IncidentStatus.urgent && incident.confirmationsCount == 0,
        icon: Icons.check_circle,
        color: AppColors.resolvedGreen,
      ),
      TimelineEvent(
        id: 'tl_2',
        title: 'En revisión',
        description: 'Patrulla asignada a la zona',
        timestamp: incident.createdAt.add(const Duration(minutes: 15)),
        isCompleted: incident.status != IncidentStatus.urgent || incident.confirmationsCount > 0,
        isCurrent: incident.status == IncidentStatus.moderate || incident.confirmationsCount > 0,
        icon: Icons.local_police,
        color: AppColors.primaryBlue,
      ),
      TimelineEvent(
        id: 'tl_3',
        title: 'Atendido',
        description: incident.status == IncidentStatus.resolved
            ? 'Incidente resuelto · ${Formatters.formatTime(incident.updatedAt)}'
            : 'Pendiente',
        timestamp: incident.updatedAt,
        isCompleted: incident.status == IncidentStatus.resolved,
        isCurrent: incident.status == IncidentStatus.resolved,
        icon: Icons.verified,
        color: AppColors.resolvedGreen,
      ),
    ];
  }
}

class _TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineItem({required this.event, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: event.isCompleted ? event.color : AppColors.surfaceSecondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: event.isCurrent ? event.color : (event.isCompleted ? event.color : AppColors.borderSecondary),
                  width: event.isCurrent ? 3 : 2,
                ),
              ),
              child: event.isCompleted
                  ? Icon(event.icon, size: 14, color: AppColors.textOnPrimary)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: event.isCompleted ? event.color.withValues(alpha: 0.5) : AppColors.borderSecondary,
                margin: const EdgeInsets.only(top: 4, bottom: 4),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(event.title, style: AppTextStyles.labelLarge.copyWith(
                    color: event.isCurrent ? event.color : AppColors.textPrimary,
                    fontWeight: event.isCurrent ? FontWeight.w600 : FontWeight.w500,
                  )),
                  if (event.isCurrent) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                      decoration: BoxDecoration(
                        color: event.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
                      ),
                      child: Text('AHORA', style: AppTextStyles.labelSmall.copyWith(color: event.color, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(event.description, style: AppTextStyles.bodySmallSecondary),
            ],
          ),
        ),
      ],
    );
  }
}