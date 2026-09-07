import 'package:flutter/material.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../shared/components/incident_card.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/basic_widgets.dart';

/// Header shared by [NearbyIncidentsCard] and [AllIncidentsCard]: collapsed
/// to just the icon, tapping the icon expands it to reveal the title/count,
/// and tapping it again collapses it back down.
Widget _buildCollapsibleHeader({
  required bool expanded,
  required VoidCallback onToggle,
  required IconData icon,
  required Gradient gradient,
  required String title,
  required String subtitle,
}) {
  return Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Pressable(
            onTap: onToggle,
            child: AppIconBadge(icon: icon, gradient: gradient, size: 36, iconSize: 18),
          ),
          if (expanded) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  Text(subtitle, style: AppTextStyles.bodySmallSecondary),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildIncidentsEmptyState(String message) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.resolvedGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle_outline, size: AppSpacing.iconMd, color: AppColors.resolvedGreen),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(message, style: AppTextStyles.bodyMediumSecondary),
        ),
      ],
    ),
  );
}

/// Inline "nearby incidents" card shown below the map search bar — a
/// floating surface consistent with [MapSearchBar], not a separate
/// draggable sheet. Collapsed by default to just its icon; tapping the icon
/// expands it to reveal the title and the horizontal carousel, and tapping
/// the icon again collapses it back down.
class NearbyIncidentsCard extends StatelessWidget {
  final List<Incident> incidents;
  final Function(Incident) onIncidentTap;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const NearbyIncidentsCard({
    super.key,
    required this.incidents,
    required this.onIncidentTap,
    required this.expanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final nearbyIncidents = incidents.where((i) => i.isNearby).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCollapsibleHeader(
            expanded: expanded,
            onToggle: onToggleExpanded,
            icon: Icons.warning_amber_outlined,
            gradient: AppColors.primaryGradient,
            title: 'Incidentes cerca de ti',
            subtitle: '${nearbyIncidents.length} incidentes cercanos',
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: nearbyIncidents.isEmpty
                        ? _buildIncidentsEmptyState('Todo tranquilo por tu zona, sin incidentes cercanos')
                        : _buildIncidentsList(nearbyIncidents),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsList(List<Incident> incidents) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 110),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: incidents.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final incident = incidents[index];

          return IncidentCard(
            incident: incident,
            onTap: () => onIncidentTap(incident),
            isHorizontal: true,
            showReporter: false,
            index: index,
          );
        },
      ),
    );
  }
}

/// Inline "all incidents" card shown below [NearbyIncidentsCard] — same
/// floating-card style and same collapse/expand-by-icon behavior. Collapsed
/// by default to just its icon; tapping the icon expands it to reveal the
/// full incident list (vertical, scrollable), and tapping it again collapses
/// it back down.
class AllIncidentsCard extends StatelessWidget {
  final List<Incident> incidents;
  final Function(Incident) onIncidentTap;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const AllIncidentsCard({
    super.key,
    required this.incidents,
    required this.onIncidentTap,
    required this.expanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCollapsibleHeader(
            expanded: expanded,
            onToggle: onToggleExpanded,
            icon: Icons.list_alt,
            gradient: AppColors.secondaryGradient,
            title: 'Todos los incidentes',
            subtitle: '${incidents.length} incidentes en total',
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: incidents.isEmpty
                        ? _buildIncidentsEmptyState('No hay incidentes registrados')
                        : _buildIncidentsList(incidents),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsList(List<Incident> incidents) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: incidents.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final incident = incidents[index];

          return IncidentCard(
            incident: incident,
            onTap: () => onIncidentTap(incident),
            isHorizontal: false,
            index: index,
          );
        },
      ),
    );
  }
}
