import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../data/repositories/emergency_repository.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/components/report_card.dart';
import '../../../../../shared/widgets/basic_widgets.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  final _emergencyRepository = EmergencyRepository();
  late Future<List<Report>> _reportsFuture;

  final List<String> _tabs = ['Todos', 'En revisión', 'Atendidos'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _reportsFuture = _emergencyRepository.listMineReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Report> _filterReports(List<Report> reports) {
    switch (_selectedTab) {
      case 1:
        return reports.where((r) => r.status == ReportStatus.inReview).toList();
      case 2:
        return reports.where((r) => r.status == ReportStatus.attended).toList();
      default:
        return reports;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Mis reportes', style: AppTextStyles.titleLarge),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondaryTeal,
          indicatorWeight: 3,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTextStyles.labelMedium,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: FutureBuilder<List<Report>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppLoadingIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: AppEmptyState(
                icon: Icons.error_outline,
                title: 'No se pudieron cargar tus reportes',
                subtitle: 'Revisa tu conexión e intenta nuevamente.',
                action: AppButton(
                  label: 'Reintentar',
                  isExpanded: false,
                  onPressed: () => setState(() {
                    _reportsFuture = _emergencyRepository.listMineReports();
                  }),
                ),
              ),
            );
          }

          final reports = _filterReports(snapshot.data ?? const <Report>[]);

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: reports.isEmpty
                ? KeyedSubtree(
                    key: ValueKey('empty_$_selectedTab'),
                    child: _buildEmptyState(),
                  )
                : ListView.separated(
                    key: ValueKey('list_$_selectedTab'),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return ReportCard(
                        report: report,
                        onTap: () => context.push('/incident/${report.id}'),
                        index: index,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    Color iconColor;

    switch (_selectedTab) {
      case 1:
        message = 'No tienes reportes en revisión';
        icon = Icons.pending_outlined;
        iconColor = AppColors.moderateOrange;
        break;
      case 2:
        message = 'No tienes reportes atendidos';
        icon = Icons.check_circle_outline;
        iconColor = AppColors.resolvedGreen;
        break;
      default:
        message = 'No has creado ningún reporte aún';
        icon = Icons.assignment_outlined;
        iconColor = AppColors.primaryBlue;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppSpacing.iconXl, color: iconColor),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Sin reportes', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
            if (_selectedTab == 0) ...[
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: AppButton(
                  label: 'Crear mi primer reporte',
                  onPressed: () => context.push('/report/create'),
                  icon: Icons.add,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}