import 'package:flutter/material.dart';
import '../../app/theme/index.dart';
import '../../core/animations/motion.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../mock/models.dart';
import '../widgets/basic_widgets.dart';

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onTap;
  final bool isHorizontal;
  final bool showDistance;
  final bool showTime;
  final bool showReporter;
  final int index;

  const IncidentCard({
    super.key,
    required this.incident,
    this.onTap,
    this.isHorizontal = false,
    this.showDistance = true,
    this.showTime = true,
    this.showReporter = true,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);
    final tappable = onTap != null ? Pressable(onTap: onTap, child: card) : card;

    return tappable.staggerChild(index);
  }

  Widget _buildCard(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontalCard(context);
    }
    return _buildVerticalCard(context);
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildTypeIcon(compact: true),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  incident.title,
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            incident.description,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _buildStatusIndicator(compact: true),
              const Spacer(),
              if (showTime)
                Text(
                  Formatters.formatRelativeTime(incident.createdAt),
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeIcon(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  incident.title,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusIndicator(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            incident.description,
            style: AppTextStyles.bodySmallSecondary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (showTime) _buildTimeChip(context),
              if (showTime && showDistance) const SizedBox(width: AppSpacing.sm),
              if (showDistance) _buildDistanceChip(context),
              const Spacer(),
              if (showReporter) Flexible(child: _buildReporterInfo(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
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
            decoration: BoxDecoration(
              color: incident.statusColor,
              shape: BoxShape.circle,
            ),
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
    );
  }

  Gradient get _typeGradient {
    if (incident.typeIcon == Icons.local_hospital_outlined) return AppColors.resolvedGradient;
    if (incident.typeIcon == Icons.warning_outlined) return AppColors.urgentGradient;
    return AppColors.primaryGradient;
  }

  Widget _buildTypeIcon({bool compact = false}) {
    return AppIconBadge(
      icon: incident.typeIcon,
      gradient: _typeGradient,
      size: compact ? 28 : 36,
      iconSize: compact ? 14 : 18,
    );
  }

  Widget _buildTimeChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: AppSpacing.iconXs, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            Formatters.formatRelativeTime(incident.createdAt),
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceChip(BuildContext context) {
    final isNearby = (incident.location.latitude - AppConstants.defaultMapLatitude).abs() < 0.01;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: AppSpacing.iconXs, color: isNearby ? AppColors.primaryBlue : AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isNearby ? 'Cerca' : 'Lejos',
            style: AppTextStyles.labelSmall.copyWith(color: isNearby ? AppColors.primaryBlue : AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildReporterInfo(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
          child: Text(
            incident.reporterName.isNotEmpty ? incident.reporterName[0].toUpperCase() : '?',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryBlue),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            incident.reporterName,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class IncidentCardHorizontalList extends StatelessWidget {
  final List<Incident> incidents;
  final VoidCallback? onIncidentTap;
  final String? title;
  final bool showTitle;

  const IncidentCardHorizontalList({
    super.key,
    required this.incidents,
    this.onIncidentTap,
    this.title,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle && title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(title!, style: AppTextStyles.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${incidents.length} incidentes',
                  style: AppTextStyles.bodySmallSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: incidents.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final incident = incidents[index];
              return IncidentCard(
                incident: incident,
                onTap: () => onIncidentTap?.call(),
                isHorizontal: true,
                showReporter: false,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class IncidentMarker extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onTap;
  final bool isSelected;

  const IncidentMarker({
    super.key,
    required this.incident,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = incident.status == IncidentStatus.urgent;

    final marker = Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: incident.statusColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: incident.statusColor.withValues(alpha: 0.5),
            blurRadius: isUrgent ? 12 : 6,
            spreadRadius: isUrgent ? 4 : 2,
          ),
        ],
        border: Border.all(color: AppColors.backgroundPrimary, width: 2),
      ),
      child: Icon(incident.typeIcon, size: AppSpacing.iconMd, color: AppColors.textOnPrimary),
    );

    return GestureDetector(
      onTap: onTap,
      child: isUrgent
          ? marker.pulseGlow(minScale: 1.0, maxScale: 1.2, minOpacity: 1.0, maxOpacity: 1.0, duration: const Duration(milliseconds: 1500))
          : marker,
    );
  }
}