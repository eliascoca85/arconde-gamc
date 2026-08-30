import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/nominatim_service.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/utils/geojson_parser.dart';
import '../../../../../data/repositories/emergency_repository.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/app_map.dart';
import '../../../../../shared/widgets/basic_widgets.dart';
import '../widgets/map_controls.dart';
import '../widgets/map_view.dart';
import '../widgets/incidents_bottom_sheet.dart';
import '../widgets/map_zone_search.dart';
import '../../../reports/presentation/pages/my_reports_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isMapExpanded = false;
  GeoSearchResult? _selectedZone;
  final _emergencyRepository = EmergencyRepository();
  late Future<List<Incident>> _incidentsFuture;
  Location _userLocation = const Location(
    latitude: AppConstants.defaultMapLatitude,
    longitude: AppConstants.defaultMapLongitude,
    address: '',
    zone: '',
  );

  List<Incident>? _visibleIncidentsSource;
  GeoSearchResult? _visibleIncidentsZone;
  List<Incident> _visibleIncidentsCache = const [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _incidentsFuture = _emergencyRepository.listMineIncidents();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLocation = Location(
          latitude: position.latitude,
          longitude: position.longitude,
          address: '',
          zone: '',
        );
      });
    }
  }

  void _onIncidentTap(Incident incident) {
    context.push('/incident/${incident.id}');
  }

  void _onReportPressed() {
    context.push('/report/create');
  }

  void _onToggleMapExpanded() {
    setState(() => _isMapExpanded = !_isMapExpanded);
  }

  void _onZoneSelected(GeoSearchResult zone) {
    setState(() => _selectedZone = zone);
  }

  void _onZoneCleared() {
    setState(() => _selectedZone = null);
  }

  void _onZoomIn() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + 1).clamp(AppMap.minZoom, AppMap.maxZoom));
  }

  void _onZoomOut() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom - 1).clamp(AppMap.minZoom, AppMap.maxZoom));
  }

  /// Incidents visible on the map: all of them, or only those inside the
  /// selected zone's real geometry (point-in-polygon, not name matching).
  /// Cached by (source list, zone) so it isn't recomputed on every rebuild.
  List<Incident> _visibleIncidents(List<Incident> incidents) {
    if (identical(incidents, _visibleIncidentsSource) &&
        _visibleIncidentsZone?.key == _selectedZone?.key) {
      return _visibleIncidentsCache;
    }

    final geometry = _selectedZone?.geometry;
    final filtered = (geometry == null || !geometry.isArea)
        ? incidents
        : incidents.where((incident) {
            final point = LatLng(incident.location.latitude, incident.location.longitude);
            return isPointInZone(point, geometry);
          }).toList();

    _visibleIncidentsSource = incidents;
    _visibleIncidentsZone = _selectedZone;
    _visibleIncidentsCache = filtered;
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeTab(),
              const MyReportsPage(),
              const NotificationsPage(),
              const ProfilePage(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: _isMapExpanded ? const SizedBox(width: double.infinity) : _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildHomeTab() {
    return FutureBuilder<List<Incident>>(
      future: _incidentsFuture,
      builder: (context, snapshot) {
        final allIncidents = snapshot.data ?? const <Incident>[];
        final incidents = _visibleIncidents(allIncidents);
        return Stack(
          children: [
            MapView(
              incidents: incidents,
              onIncidentTap: _onIncidentTap,
              userLocation: _userLocation,
              isExpanded: _isMapExpanded,
              onToggleExpand: _onToggleMapExpanded,
              zone: _selectedZone,
              mapController: _mapController,
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: IgnorePointer(
                      ignoring: _isMapExpanded,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _isMapExpanded ? 0 : 1,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          offset: _isMapExpanded ? const Offset(0, -0.1) : Offset.zero,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ListView(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              children: [_buildTopBar(snapshot, incidents)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildBottomActionBar(),
                ],
              ),
            ),
            // Last Stack child so it wins hit-testing over the top-bar's
            // full-width Scrollable above (a ListView always claims its
            // whole viewport for drag detection, even past its visible
            // content, so the zoom buttons must sit on a later/topmost
            // layer to receive taps at all in that region).
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: _topZoomControlsOffset, right: AppSpacing.md),
                  child: MapZoomControls(onZoomIn: _onZoomIn, onZoomOut: _onZoomOut),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static const double _topZoomControlsOffset = 96;

  Widget _buildTopBar(AsyncSnapshot<List<Incident>> snapshot, List<Incident> incidents) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MapZoneSearchField(
            selectedZone: _selectedZone,
            filteredCount: _selectedZone == null ? null : incidents.length,
            onZoneSelected: _onZoneSelected,
            onZoneCleared: _onZoneCleared,
            onFilterPressed: _showFilterSheet,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (snapshot.connectionState != ConnectionState.done)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: AppLoadingIndicator()),
            )
          else if (snapshot.hasError)
            AppEmptyState(
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
            )
          else ...[
            NearbyIncidentsCard(
              incidents: incidents,
              onIncidentTap: _onIncidentTap,
            ),
            const SizedBox(height: AppSpacing.sm),
            AllIncidentsCard(
              incidents: incidents,
              onIncidentTap: _onIncidentTap,
            ),
          ],
        ],
      ),
    ).immersiveEntrance(distance: -0.08);
  }

  Widget _buildBottomActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppFAB(
            onPressed: _onReportPressed,
            isExtended: true,
            label: 'Reportar',
            icon: Icons.emergency_outlined,
            backgroundColor: AppColors.urgentRed,
          ).pulseGlow(
            minScale: 1.0,
            maxScale: 1.04,
            minOpacity: 1.0,
            maxOpacity: 1.0,
            duration: const Duration(milliseconds: 2200),
          ),
        ],
      ),
    ).immersiveEntrance(delay: const Duration(milliseconds: 500));
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        onFilterChanged: (filters) {},
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      height: 72,
      indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.2),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Mapa',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: 'Mis Reportes',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: 'Notificaciones',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final Function(Map<String, bool>) onFilterChanged;

  const _FilterBottomSheet({required this.onFilterChanged});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  final Map<String, bool> _filters = {
    'urgente': true,
    'moderado': true,
    'resuelto': true,
    'robo': true,
    'accidente': true,
    'persona_sospechosa': true,
    'violencia': true,
    'incendio': true,
    'emergencia_medica': true,
    'vandalismo': true,
    'otro': true,
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Text('Filtros', style: AppTextStyles.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _filters.updateAll((key, value) => true);
                        setState(() {});
                      },
                      child: Text('Todos', style: AppTextStyles.labelMedium),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Text('Nivel de urgencia', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildFilterChip('urgente', 'Urgente', AppColors.urgentRed),
                        _buildFilterChip('moderado', 'Moderado', AppColors.moderateOrange),
                        _buildFilterChip('resuelto', 'Resuelto', AppColors.resolvedGreen),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Tipo de incidente', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildFilterChip('robo', 'Robo', AppColors.urgentRed),
                        _buildFilterChip('accidente', 'Accidente', AppColors.moderateOrange),
                        _buildFilterChip('persona_sospechosa', 'Persona sospechosa', AppColors.primaryBlue),
                        _buildFilterChip('violencia', 'Violencia', AppColors.urgentRed),
                        _buildFilterChip('incendio', 'Incendio', AppColors.urgentRed),
                        _buildFilterChip('emergencia_medica', 'Emergencia médica', AppColors.resolvedGreen),
                        _buildFilterChip('vandalismo', 'Vandalismo', AppColors.moderateOrange),
                        _buildFilterChip('otro', 'Otro', AppColors.textTertiary),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton(
                  label: 'Aplicar filtros',
                  onPressed: () {
                    widget.onFilterChanged(_filters);
                    Navigator.pop(context);
                  },
                  isExpanded: true,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label, Color color) {
    final isSelected = _filters[key] ?? false;
    return FilterChip(
      label: Text(label, style: AppTextStyles.labelMedium),
      selected: isSelected,
      onSelected: (value) => setState(() => _filters[key] = value),
      selectedColor: color.withValues(alpha: 0.2),
      backgroundColor: AppColors.surfaceSecondary,
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: isSelected ? color : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? color : AppColors.borderPrimary,
        width: isSelected ? 1.5 : 0.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}