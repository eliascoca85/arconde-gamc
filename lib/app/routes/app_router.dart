import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/index.dart';
import '../../../shared/widgets/basic_widgets.dart';
import '../../../features/home/presentation/pages/home_page.dart';
import '../../../features/map/presentation/pages/map_page.dart';
import '../../../features/incident_detail/presentation/pages/incident_detail_page.dart';
import '../../../features/reports/presentation/pages/create_report_page.dart';
import '../../../features/reports/presentation/pages/ai_report_page.dart';
import '../../../features/reports/presentation/pages/my_reports_page.dart';
import '../../../features/notifications/presentation/pages/notifications_page.dart';
import '../../../features/profile/presentation/pages/profile_page.dart';
import '../../../features/profile/presentation/pages/favorite_zones_page.dart';
import '../../../features/profile/presentation/pages/settings_page.dart';
import '../../../features/profile/presentation/pages/privacy_page.dart';
import '../../../features/profile/presentation/pages/help_support_page.dart';
import '../../../features/profile/presentation/pages/about_page.dart';

class AppRouter {
  static const String home = '/';
  static const String map = '/map';
  static const String incidentDetail = '/incident/:id';
  static const String createReport = '/report/create';
  static const String aiReport = '/report/ai';
  static const String myReports = '/reports/my';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String favoriteZones = '/profile/favorite-zones';
  static const String settings = '/profile/settings';
  static const String privacy = '/profile/privacy';
  static const String helpSupport = '/profile/help';
  static const String about = '/profile/about';
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
        builder: (context, state) {
          final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
          final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');
          final incidentId = state.uri.queryParameters['incidentId'];
          return MapPage(
            focusLatitude: lat,
            focusLongitude: lng,
            focusIncidentId: incidentId,
          );
        },
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
        path: aiReport,
        name: 'ai-report',
        builder: (context, state) => const AiReportPage(),
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
        path: favoriteZones,
        name: 'favorite-zones',
        builder: (context, state) => const FavoriteZonesPage(),
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: privacy,
        name: 'privacy',
        builder: (context, state) => const PrivacyPage(),
      ),
      GoRoute(
        path: helpSupport,
        name: 'help-support',
        builder: (context, state) => const HelpSupportPage(),
      ),
      GoRoute(
        path: about,
        name: 'about',
        builder: (context, state) => const AboutPage(),
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