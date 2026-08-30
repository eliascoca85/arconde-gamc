import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/network/nominatim_service.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/app_map.dart';
import 'map_controls.dart';

class MapView extends StatefulWidget {
  final List<Incident> incidents;
  final Function(Incident)? onIncidentTap;
  final Location userLocation;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final GeoSearchResult? zone;
  final MapController mapController;

  const MapView({
    super.key,
    required this.incidents,
    this.onIncidentTap,
    required this.userLocation,
    this.isExpanded = false,
    this.onToggleExpand,
    this.zone,
    required this.mapController,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Incident? _selectedIncident;
  MapController get _mapController => widget.mapController;
  LatLng _mapCenter = const LatLng(-17.3895, -66.1568);
  LatLng? _liveUserLocation;
  bool _isLocating = false;

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
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.zone != null && widget.zone?.key != oldWidget.zone?.key) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: widget.zone!.bounds,
            padding: const EdgeInsets.all(48),
            maxZoom: AppMap.maxZoom,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onIncidentTap(Incident incident) {
    setState(() => _selectedIncident = incident);
    widget.onIncidentTap?.call(incident);

    final point = LatLng(incident.location.latitude, incident.location.longitude);
    _mapController.move(point, 16.0);
  }

  Future<void> _onLocateMePressed() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    final result = await LocationService.getCurrentPositionResult();
    if (!mounted) return;
    setState(() => _isLocating = false);

    switch (result.status) {
      case LocationResultStatus.success:
        final point = LatLng(result.position!.latitude, result.position!.longitude);
        setState(() => _liveUserLocation = point);
        _mapController.move(point, 16.0);
        break;
      case LocationResultStatus.serviceDisabled:
        _showLocationMessage('Activa el GPS de tu dispositivo para ver tu ubicación.');
        break;
      case LocationResultStatus.permissionDenied:
        _showLocationMessage('Necesitamos permiso de ubicación para mostrarte en el mapa.');
        break;
      case LocationResultStatus.permissionDeniedForever:
        _showLocationMessage('El permiso de ubicación está bloqueado. Actívalo desde los ajustes del sistema.');
        break;
      case LocationResultStatus.error:
        _showLocationMessage('No se pudo obtener tu ubicación. Intenta nuevamente.');
        break;
    }
  }

  void _showLocationMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final userPoint = _liveUserLocation ?? LatLng(widget.userLocation.latitude, widget.userLocation.longitude);
    final zoneGeometry = widget.zone?.geometry;

    return Stack(
      children: [
        AppMap(
          center: _mapCenter,
          zoom: 15.0,
          incidents: widget.incidents,
          selectedIncident: _selectedIncident,
          onIncidentTap: _onIncidentTap,
          userLocation: userPoint,
          mapController: _mapController,
          interactive: true,
          zonePolygons: zoneGeometry?.polygons ?? const [],
          zoneLines: zoneGeometry?.lines ?? const [],
        ),
        // Zoom controls are rendered by HomePage, above its top-bar
        // Scrollable in the outer Stack, so they win hit-testing over that
        // full-width viewport (see home_page.dart's _buildHomeTab).
        Positioned(
          bottom: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: _bottomControlsOffset, right: AppSpacing.md),
              child: MapActionControls(
                onToggleFullscreen: widget.onToggleExpand ?? () {},
                isFullscreen: widget.isExpanded,
                onLocateMe: _onLocateMePressed,
                isLocating: _isLocating,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const double _bottomControlsOffset = 96;
