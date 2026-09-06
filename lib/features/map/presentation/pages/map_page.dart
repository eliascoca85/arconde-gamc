import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/services/report_events.dart';
import '../../../../../core/services/routing_service.dart';
import '../../../../../data/repositories/emergency_repository.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/app_map.dart';
import '../../../../../shared/widgets/auth_gate.dart';
import '../../../../../shared/widgets/basic_widgets.dart';

class MapPage extends StatefulWidget {
  final double? focusLatitude;
  final double? focusLongitude;
  final String? focusIncidentId;

  const MapPage({
    super.key,
    this.focusLatitude,
    this.focusLongitude,
    this.focusIncidentId,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Incident? _selectedIncident;
  final MapController _mapController = MapController();
  final _emergencyRepository = EmergencyRepository();
  late Future<List<Incident>> _incidentsFuture;
  late LatLng _mapCenter;
  LatLng _userLocation = const LatLng(-17.3895, -66.1568);
  LatLng? _focusPoint;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _routeFailed = false;

  bool get _hasFocus => _focusPoint != null;

  @override
  void initState() {
    super.initState();
    if (widget.focusLatitude != null && widget.focusLongitude != null) {
      _focusPoint = LatLng(widget.focusLatitude!, widget.focusLongitude!);
    }
    _mapCenter = _focusPoint ?? const LatLng(-17.3895, -66.1568);
    _incidentsFuture = _emergencyRepository.listPublicIncidents().then((incidents) {
      if (widget.focusIncidentId != null && mounted) {
        final matches = incidents.where((i) => i.id == widget.focusIncidentId);
        if (matches.isNotEmpty) {
          setState(() => _selectedIncident = matches.first);
        }
      }
      return incidents;
    });
    _loadUserLocation();
    if (_hasFocus) {
      _fetchRoute();
    }
    ReportEvents.submitted.addListener(_onReportSubmitted);
  }

  Future<void> _loadUserLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        if (!_hasFocus) {
          _mapCenter = _userLocation;
        }
      });
      if (_hasFocus) {
        _fetchRoute();
      }
    }
  }

  Future<void> _fetchRoute() async {
    if (_focusPoint == null) return;
    setState(() {
      _isLoadingRoute = true;
      _routeFailed = false;
    });
    final route = await RoutingService.fetchRoute(_userLocation, _focusPoint!);
    if (!mounted) return;
    setState(() {
      _isLoadingRoute = false;
      if (route != null && route.isNotEmpty) {
        _routePoints = route;
        _routeFailed = false;
      } else {
        _routePoints = [_userLocation, _focusPoint!];
        _routeFailed = true;
      }
    });
  }

  void _onReportSubmitted() {
    if (!mounted) return;
    setState(() {
      _incidentsFuture = _emergencyRepository.listPublicIncidents();
    });
  }

  @override
  void dispose() {
    ReportEvents.submitted.removeListener(_onReportSubmitted);
    _mapController.dispose();
    super.dispose();
  }

  void _onIncidentTap(Incident incident) {
    setState(() => _selectedIncident = incident);
    final point = LatLng(incident.location.latitude, incident.location.longitude);
    _mapController.move(point, 16.0);
    context.push('/incident/${incident.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Incident>>(
        future: _incidentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppLoadingIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: AppEmptyState(
                icon: Icons.error_outline,
                title: 'No se pudieron cargar los incidentes',
                subtitle: 'Revisa tu conexión e intenta nuevamente.',
                action: AppButton(
                  label: 'Reintentar',
                  isExpanded: false,
                  onPressed: () => setState(() {
                    _incidentsFuture = _emergencyRepository.listPublicIncidents();
                  }),
                ),
              ),
            );
          }

          final incidents = snapshot.data ?? const <Incident>[];
          return Stack(
            children: [
              AppMap(
                center: _mapCenter,
                zoom: _hasFocus ? 16.0 : 15.0,
                incidents: incidents,
                selectedIncident: _selectedIncident,
                onIncidentTap: _onIncidentTap,
                userLocation: _userLocation,
                mapController: _mapController,
                interactive: true,
                zoneLines: _routePoints.isNotEmpty ? [_routePoints] : const [],
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    if (_hasFocus) _buildRouteStatusBanner(),
                    const Spacer(),
                  ],
                ),
              ),
              _buildReportFAB(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (_hasFocus && Navigator.of(context).canPop())
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                border: Border.all(color: AppColors.borderPrimary, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.textTertiary, size: AppSpacing.iconMd),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Buscar en el mapa...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled)),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(color: AppColors.borderPrimary, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.layers_outlined, color: AppColors.primaryBlue, size: AppSpacing.iconMd),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStatusBanner() {
    if (!_isLoadingRoute && !_routeFailed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoadingRoute)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.info_outline, size: AppSpacing.iconSm, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _isLoadingRoute ? 'Calculando ruta...' : 'No se pudo calcular la ruta por calles',
                style: AppTextStyles.bodySmallSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportFAB() {
    return Positioned(
      bottom: 100,
      right: AppSpacing.md,
      child: FloatingActionButton.extended(
        onPressed: () async {
          if (!await ensureAuthenticated(context)) return;
          if (!mounted) return;
          context.push('/report/create');
        },
        backgroundColor: AppColors.secondaryTeal,
        foregroundColor: AppColors.textOnPrimary,
        elevation: AppSpacing.elevationMd,
        icon: const Icon(Icons.add_rounded),
        label: Text('Reportar', style: AppTextStyles.labelLarge),
        extendedPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl)),
      ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.5, end: 0),
    );
  }
}