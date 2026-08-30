import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../data/repositories/emergency_repository.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/basic_widgets.dart';
import '../widgets/map_view.dart';
import '../widgets/incidents_bottom_sheet.dart';
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
  final _emergencyRepository = EmergencyRepository();
  late Future<List<Incident>> _incidentsFuture;
  Location _userLocation = const Location(
    latitude: AppConstants.defaultMapLatitude,
    longitude: AppConstants.defaultMapLongitude,
    address: '',
    zone: '',
  );

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
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomeTab() {
    return FutureBuilder<List<Incident>>(
      future: _incidentsFuture,
      builder: (context, snapshot) {
        final incidents = snapshot.data ?? const <Incident>[];
        return Stack(
          children: [
            MapView(
              incidents: incidents,
              onIncidentTap: _onIncidentTap,
              userLocation: _userLocation,
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ListView(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        children: [_buildTopBar(snapshot, incidents)],
                      ),
                    ),
                  ),
                  _buildBottomActionBar(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(AsyncSnapshot<List<Incident>> snapshot, List<Incident> incidents) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MapSearchBar(
            controller: TextEditingController(),
            onTap: () => context.push('/search'),
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