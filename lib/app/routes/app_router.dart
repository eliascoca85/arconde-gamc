import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/index.dart';
import '../../../shared/widgets/basic_widgets.dart';
import '../../../features/home/presentation/pages/home_page.dart';
import '../../../features/map/presentation/pages/map_page.dart';
import '../../../features/incident_detail/presentation/pages/incident_detail_page.dart';
import '../../../features/reports/presentation/pages/create_report_page.dart';
import '../../../features/reports/presentation/pages/my_reports_page.dart';
import '../../../features/notifications/presentation/pages/notifications_page.dart';
import '../../../features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static const String home = '/';
  static const String map = '/map';
  static const String incidentDetail = '/incident/:id';
  static const String createReport = '/report/create';
  static const String myReports = '/reports/my';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String search = '/search';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: map,
        name: 'map',
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: incidentDetail,
        name: 'incident-detail',
        builder: (context, state) {
          final incidentId = state.pathParameters['id'] ?? '';
          return IncidentDetailPage(incidentId: incidentId);
        },
      ),
      GoRoute(
        path: createReport,
        name: 'create-report',
        builder: (context, state) => const CreateReportPage(),
      ),
      GoRoute(
        path: myReports,
        name: 'my-reports',
        builder: (context, state) => const MyReportsPage(),
      ),
      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: search,
        name: 'search',
        builder: (context, state) => const _SearchPage(),
      ),
    ],
    errorBuilder: (context, state) => const _ErrorPage(),
  );
}

class _SearchPage extends StatelessWidget {
  const _SearchPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(title: const Text('Buscar')),
      body: const Center(child: Text('Búsqueda - En desarrollo')),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, size: AppSpacing.iconXl * 1.5, color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Página no encontrada', style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              Text('La ruta solicitada no existe', style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Ir al inicio',
                onPressed: () => context.go(AppRouter.home),
                icon: Icons.home,
              ),
            ],
          ),
        ),
      ),
    );
  }
}