import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../app/theme/index.dart';
import '../../../../features/map/presentation/widgets/map_markers.dart';
import '../../../../mock/models.dart';
import '../../../../shared/widgets/basic_widgets.dart';

class AppMap extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Incident> incidents;
  final Incident? selectedIncident;
  final Function(Incident)? onIncidentTap;
  final LatLng? userLocation;
  final bool showUserLocation;
  final bool interactive;
  final MapController? mapController;
  final Function(LatLng)? onMapTap;
  final List<Marker> Function()? additionalMarkers;

  const AppMap({
    super.key,
    this.center = const LatLng(-17.3895, -66.1568),
    this.zoom = 15.0,
    this.incidents = const [],
    this.selectedIncident,
    this.onIncidentTap,
    this.userLocation,
    this.showUserLocation = true,
    this.interactive = true,
    this.mapController,
    this.onMapTap,
    this.additionalMarkers,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 10.0,
        maxZoom: 19.0,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onTap: onMapTap != null
            ? (tapPosition, point) => onMapTap!(point)
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.arconte.app',
          maxZoom: 19,
          tileProvider: NetworkTileProvider(),
        ),
        if (userLocation != null && showUserLocation)
          _buildUserLocationLayer(userLocation!),
        _buildIncidentMarkersLayer(),
        if (additionalMarkers != null)
          MarkerLayer(markers: additionalMarkers!()),
      ],
    );
  }

  Widget _buildUserLocationLayer(LatLng location) {
    return MarkerLayer(
      markers: [
        Marker(
          point: location,
          width: 48,
          height: 48,
          child: const UserLocationMarker(),
        ),
      ],
    );
  }

  Widget _buildIncidentMarkersLayer() {
    return MarkerLayer(
      markers: incidents.asMap().entries.map((entry) {
        final _ = entry.key;
        final incident = entry.value;
        final isSelected = selectedIncident?.id == incident.id;
        final point = LatLng(incident.location.latitude, incident.location.longitude);

        return Marker(
          point: point,
          width: isSelected ? 56 : 44,
          height: isSelected ? 56 : 44,
          child: AnimatedMarker(
            incident: incident,
            isSelected: isSelected,
            onTap: () => onIncidentTap?.call(incident),
          ),
        );
      }).toList(),
    );
  }
}

class AppMapPicker extends StatefulWidget {
  final LatLng initialPosition;
  final Function(LatLng) onLocationSelected;
  final String? title;
  final LatLng? userLocation;

  const AppMapPicker({
    super.key,
    required this.initialPosition,
    required this.onLocationSelected,
    this.title,
    this.userLocation,
  });

  @override
  State<AppMapPicker> createState() => _AppMapPickerState();
}

class _AppMapPickerState extends State<AppMapPicker> {
  late LatLng _selectedPosition;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(widget.title!, style: AppTextStyles.titleMedium),
          ),
        Expanded(
          child: AppMap(
            center: _selectedPosition,
            zoom: 16.0,
            mapController: _mapController,
            userLocation: widget.userLocation,
            interactive: true,
            onMapTap: (point) {
              setState(() => _selectedPosition = point);
              widget.onLocationSelected(point);
            },
            additionalMarkers: () => [
              Marker(
                point: _selectedPosition,
                width: 48,
                height: 48,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.urgentRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.urgentRed.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: AppColors.backgroundPrimary, width: 2),
                  ),
                  child: Icon(Icons.location_on, size: 24, color: AppColors.textOnPrimary),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (widget.userLocation != null)
                  Expanded(
                    child: AppOutlinedButton(
                      label: 'Mi ubicación',
                      onPressed: () {
                        _mapController.move(widget.userLocation!, 16.0);
                        setState(() => _selectedPosition = widget.userLocation!);
                        widget.onLocationSelected(widget.userLocation!);
                      },
                      icon: Icons.my_location,
                    ),
                  ),
                if (widget.userLocation != null) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: 'Confirmar ubicación',
                    onPressed: () => widget.onLocationSelected(_selectedPosition),
                    icon: Icons.check,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}