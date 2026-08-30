import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../data/repositories/emergency_repository.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/app_map.dart';
import '../../../../../shared/widgets/basic_widgets.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Incident? _selectedIncident;
  final MapController _mapController = MapController();
  final _emergencyRepository = EmergencyRepository();
  late Future<List<Incident>> _incidentsFuture;
  LatLng _mapCenter = const LatLng(-17.3895, -66.1568);
  LatLng _userLocation = const LatLng(-17.3895, -66.1568);

  @override
  void initState() {
    super.initState();
    _incidentsFuture = _emergencyRepository.listMineIncidents();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _mapCenter = _userLocation;
      });
    }
  }

  @override
  void dispose() {
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
                title: 'No se pudieron cargar tus incidentes',
                subtitle: 'Revisa tu conexión e intenta nuevamente.',
                action: AppButton(
                  label: 'Reintentar',
                  isExpanded: false,
                  onPressed: () => setState(() {
                    _incidentsFuture = _emergencyRepository.listMineIncidents();
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
                zoom: 15.0,
                incidents: incidents,
                selectedIncident: _selectedIncident,
                onIncidentTap: _onIncidentTap,
                userLocation: _userLocation,
                mapController: _mapController,
                interactive: true,
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
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

  Widget _buildReportFAB() {
    return Positioned(
      bottom: 100,
      right: AppSpacing.md,
      child: FloatingActionButton.extended(
        onPressed: () => context.push('/report/create'),
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