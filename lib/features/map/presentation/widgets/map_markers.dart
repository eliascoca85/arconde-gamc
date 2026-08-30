import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../mock/models.dart';

class MapMarkersLayer extends StatelessWidget {
  final List<Incident> incidents;
  final Function(Incident)? onIncidentTap;
  final Incident? selectedIncident;
  final Size screenSize;

  const MapMarkersLayer({
    super.key,
    required this.incidents,
    this.onIncidentTap,
    this.selectedIncident,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: incidents.asMap().entries.map((entry) {
        final index = entry.key;
        final incident = entry.value;
        return _buildMarker(incident, index);
      }).toList(),
    );
  }

  Widget _buildMarker(Incident incident, int index) {
    final normalizedLat = (incident.location.latitude - (-17.4)) / 0.02;
    final normalizedLng = (incident.location.longitude - (-66.17)) / 0.03;

    final left = (normalizedLng * screenSize.width * 0.8).clamp(20.0, screenSize.width - 60);
    final top = ((1 - normalizedLat) * screenSize.height * 0.6).clamp(100.0, screenSize.height - 200);

    final isSelected = selectedIncident?.id == incident.id;

    return Positioned(
      left: left,
      top: top,
      child: AnimatedMarker(
        incident: incident,
        isSelected: isSelected,
        onTap: () => onIncidentTap?.call(incident),
      ).animate(delay: (80 * index).ms).fadeIn(duration: 300.ms).scale(begin: const Offset(0.3, 0.3)),
    );
  }
}

class AnimatedMarker extends StatelessWidget {
  final Incident incident;
  final bool isSelected;
  final VoidCallback? onTap;

  const AnimatedMarker({
    super.key,
    required this.incident,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = incident.status == IncidentStatus.urgent;
    final marker = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: incident.statusColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: incident.statusColor.withValues(alpha: isUrgent ? 0.6 : 0.4),
            blurRadius: isUrgent ? 16 : 8,
            spreadRadius: isUrgent ? 4 : 2,
          ),
        ],
        border: Border.all(
          color: AppColors.backgroundPrimary,
          width: isSelected ? 3 : 2,
        ),
      ),
      child: Icon(incident.typeIcon, size: 20, color: AppColors.textOnPrimary),
    );

    final scaled = !isUrgent && isSelected ? Transform.scale(scale: 1.2, child: marker) : marker;
    final animated = isUrgent
        ? scaled.pulseGlow(
            minScale: 1.0,
            maxScale: 1.15,
            minOpacity: 0.4,
            maxOpacity: 1.0,
            duration: const Duration(milliseconds: 1500),
          )
        : scaled;

    return GestureDetector(onTap: onTap, child: animated);
  }
}

class ClusterMarker extends StatelessWidget {
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const ClusterMarker({
    super.key,
    required this.count,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: AppColors.backgroundPrimary, width: 2),
        ),
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
        ).pulseGlow(
          minScale: 1.0,
          maxScale: 1.3,
          minOpacity: 0.15,
          maxOpacity: 0.0,
          duration: const Duration(milliseconds: 1500),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.backgroundPrimary, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.navigation, size: 14, color: AppColors.textOnPrimary),
        ),
      ],
    );
  }
}