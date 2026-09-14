import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../app/routes/app_router.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/nominatim_service.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/services/report_events.dart';
import '../../../../../core/services/settings_events.dart';
import '../../../../../core/services/settings_store.dart';
import '../../../../../core/utils/geojson_parser.dart';
import '../../../../../data/repositories/emergency_repository.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/app_map.dart';
import '../../../../../shared/widgets/auth_gate.dart';
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
  int _visibleIncidentsFilterVersion = -1;
  List<Incident> _visibleIncidentsCache = const [];
  final MapController _mapController = MapController();

  static const Map<String, bool> _defaultIncidentFilters = {
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
  Map<String, bool> _incidentFilters = Map.of(_defaultIncidentFilters);
  int _filterVersion = 0;

  List<FavoriteZone> _favoriteZones = const [];
  String? _applyingFavoriteKey;

  bool _nearbyIncidentsExpanded = false;
  bool _allIncidentsExpanded = false;
  bool get _anyIncidentsCardExpanded => _nearbyIncidentsExpanded || _allIncidentsExpanded;

  void _toggleNearbyIncidents() {
    setState(() {
      _nearbyIncidentsExpanded = !_nearbyIncidentsExpanded;
      if (_nearbyIncidentsExpanded) _allIncidentsExpanded = false;
    });
  }

  void _toggleAllIncidents() {
    setState(() {
      _allIncidentsExpanded = !_allIncidentsExpanded;
      if (_allIncidentsExpanded) _nearbyIncidentsExpanded = false;
    });
  }

  void _collapseIncidentCards() {
    if (!_anyIncidentsCardExpanded) return;
    setState(() {
      _nearbyIncidentsExpanded = false;
      _allIncidentsExpanded = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _incidentsFuture = _emergencyRepository.listPublicIncidents();
    _loadUserLocation();
    _loadFavoriteZones();
    ReportEvents.submitted.addListener(_onReportSubmitted);
    SettingsEvents.favoriteZonesChanged.addListener(_loadFavoriteZones);
  }

  @override
  void dispose() {
    ReportEvents.submitted.removeListener(_onReportSubmitted);
    SettingsEvents.favoriteZonesChanged.removeListener(_loadFavoriteZones);
    _mapController.dispose();
    super.dispose();
  }

  void _onReportSubmitted() {
    if (!mounted) return;
    setState(() {
      _incidentsFuture = _emergencyRepository.listPublicIncidents();
    });
  }

  Future<void> _loadFavoriteZones() async {
    final zones = await SettingsStore.loadFavoriteZones();
    if (!mounted) return;
    setState(() => _favoriteZones = zones);
  }

  /// Applies a saved favorite as the active search zone — re-resolving it
  /// by its stable OSM id to get fresh, full geometry (see
  /// [NominatimService.lookup]) rather than trusting cached coordinates,
  /// so it filters incidents exactly like picking it from the search bar.
  Future<void> _applyFavoriteZone(FavoriteZone zone) async {
    setState(() => _applyingFavoriteKey = zone.key);
    final result = await NominatimService.lookup(zone.osmType, zone.osmId);
    if (!mounted) return;
    setState(() => _applyingFavoriteKey = null);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo aplicar esa zona. Intenta nuevamente.')),
      );
      return;
    }
    _onZoneSelected(result);
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

  void _onReportPressed() async {
    if (!await ensureAuthenticated(context)) return;
    if (!mounted) return;
    context.push(AppRouter.aiReport);
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
        _visibleIncidentsZone?.key == _selectedZone?.key &&
        _visibleIncidentsFilterVersion == _filterVersion) {
      return _visibleIncidentsCache;
    }

    final geometry = _selectedZone?.geometry;
    Iterable<Incident> filtered = (geometry == null || !geometry.isArea)
        ? incidents
        : incidents.where((incident) {
            final point = LatLng(incident.location.latitude, incident.location.longitude);
            return isPointInZone(point, geometry);
          });

    filtered = filtered.where((incident) =>
        (_incidentFilters[incident.status.value] ?? true) &&
        (_incidentFilters[incident.type.value] ?? true));

    final result = filtered.toList();

    _visibleIncidentsSource = incidents;
    _visibleIncidentsZone = _selectedZone;
    _visibleIncidentsFilterVersion = _filterVersion;
    _visibleIncidentsCache = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
              onMapTap: _collapseIncidentCards,
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
                child: IgnorePointer(
                  ignoring: _anyIncidentsCardExpanded,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    opacity: _anyIncidentsCardExpanded ? 0 : 1,
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.only(top: _topZoomControlsOffset, right: AppSpacing.md),
                      child: MapZoomControls(onZoomIn: _onZoomIn, onZoomOut: _onZoomOut),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static const double _baseZoomControlsOffset = 96;
  // Height of the favorite-zone chips row plus the gap below it (see
  // _buildFavoriteZoneChips/_buildTopBar) — added on top of the base offset
  // so the zoom buttons drop down and clear the chips instead of covering
  // them, the same way the rest of the top bar accommodates that row.
  static const double _favoriteZoneChipsExtraOffset = 44;

  double get _topZoomControlsOffset {
    final showsFavoriteChips = _selectedZone == null && _favoriteZones.isNotEmpty;
    return _baseZoomControlsOffset + (showsFavoriteChips ? _favoriteZoneChipsExtraOffset : 0);
  }

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
          if (_selectedZone == null && _favoriteZones.isNotEmpty) ...[
            _buildFavoriteZoneChips(),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (snapshot.connectionState != ConnectionState.done)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: AppLoadingIndicator()),
            )
          else if (snapshot.hasError)
            AppEmptyState(
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
            )
          else ...[
            NearbyIncidentsCard(
              incidents: incidents,
              onIncidentTap: _onIncidentTap,
              expanded: _nearbyIncidentsExpanded,
              onToggleExpanded: _toggleNearbyIncidents,
            ),
            const SizedBox(height: AppSpacing.sm),
            AllIncidentsCard(
              incidents: incidents,
              onIncidentTap: _onIncidentTap,
              expanded: _allIncidentsExpanded,
              onToggleExpanded: _toggleAllIncidents,
            ),
          ],
        ],
      ),
    ).immersiveEntrance(distance: -0.08);
  }

  Widget _buildFavoriteZoneChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _favoriteZones.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final zone = _favoriteZones[index];
            final isLoading = _applyingFavoriteKey == zone.key;
            return AppChip(
              label: zone.primaryLabel,
              icon: Icons.star,
              onTap: isLoading ? null : () => _applyFavoriteZone(zone),
            );
          },
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        initialFilters: _incidentFilters,
        onFilterChanged: (filters) {
          setState(() {
            _incidentFilters = filters;
            _filterVersion++;
          });
        },
      ),
    );
  }

  static const double _centerButtonSize = 64;
  static const double _centerButtonRaise = 24;

  Widget _buildBottomNavBar() {
    return SizedBox(
      height: AppSpacing.bottomNavHeight + _centerButtonRaise,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: AppSpacing.bottomNavHeight,
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: AppSpacing.elevationMd,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(child: _buildNavItem(0, Icons.map_outlined, Icons.map, 'Mapa')),
                    Expanded(child: _buildNavItem(1, Icons.assignment_outlined, Icons.assignment, 'Mis Reportes')),
                    SizedBox(width: _centerButtonSize + AppSpacing.sm),
                    Expanded(child: _buildNavItem(2, Icons.notifications_outlined, Icons.notifications, 'Notificaciones')),
                    Expanded(child: _buildNavItem(3, Icons.person_outline, Icons.person, 'Perfil')),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: _buildReportNavButton()),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primaryDark : AppColors.textTertiary;
    return Pressable(
      onTap: () => setState(() {
        _currentIndex = index;
        _nearbyIncidentsExpanded = false;
        _allIncidentsExpanded = false;
      }),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? selectedIcon : icon, color: color, size: AppSpacing.iconMd),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportNavButton() {
    return Pressable(
      onTap: _onReportPressed,
      child: Container(
        width: _centerButtonSize,
        height: _centerButtonSize,
        decoration: BoxDecoration(
          gradient: AppColors.urgentGradient,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfacePrimary, width: 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.urgentRed.withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(Icons.emergency_outlined, color: AppColors.textOnPrimary, size: AppSpacing.iconLg),
      ),
    ).pulseGlow(
      minScale: 1.0,
      maxScale: 1.04,
      minOpacity: 1.0,
      maxOpacity: 1.0,
      duration: const Duration(milliseconds: 2200),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final Map<String, bool> initialFilters;
  final Function(Map<String, bool>) onFilterChanged;

  const _FilterBottomSheet({required this.initialFilters, required this.onFilterChanged});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late final Map<String, bool> _filters = Map.of(widget.initialFilters);

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