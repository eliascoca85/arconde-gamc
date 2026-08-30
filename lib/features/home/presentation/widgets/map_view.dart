import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/app_map.dart';

class MapView extends StatefulWidget {
  final List<Incident> incidents;
  final Function(Incident)? onIncidentTap;
  final Location userLocation;

  const MapView({
    super.key,
    required this.incidents,
    this.onIncidentTap,
    required this.userLocation,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Incident? _selectedIncident;
  final MapController _mapController = MapController();
  LatLng _mapCenter = const LatLng(-17.3895, -66.1568);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _mapCenter = LatLng(widget.userLocation.latitude, widget.userLocation.longitude);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onIncidentTap(Incident incident) {
    setState(() => _selectedIncident = incident);
    widget.onIncidentTap?.call(incident);

    final point = LatLng(incident.location.latitude, incident.location.longitude);
    _mapController.move(point, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return AppMap(
      center: _mapCenter,
      zoom: 15.0,
      incidents: widget.incidents,
      selectedIncident: _selectedIncident,
      onIncidentTap: _onIncidentTap,
      userLocation: LatLng(widget.userLocation.latitude, widget.userLocation.longitude),
      mapController: _mapController,
      interactive: true,
    );
  }
}

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onTap;
  final String hintText;
  final VoidCallback? onFilterPressed;

  const MapSearchBar({
    super.key,
    required this.controller,
    this.onTap,
    this.hintText = 'Buscar zona o dirección',
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: AppSpacing.elevationMd,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
          prefixIcon: Icon(Icons.search, color: AppColors.textTertiary, size: AppSpacing.iconMd),
          suffixIcon: IconButton(
            icon: Icon(Icons.tune, color: AppColors.textTertiary, size: AppSpacing.iconMd),
            onPressed: onFilterPressed,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0);
  }
}

