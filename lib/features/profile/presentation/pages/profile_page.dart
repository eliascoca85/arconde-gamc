import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../core/network/auth_service.dart';
import '../../../../../core/network/load_error.dart';
import '../../../../../data/mappers.dart';
import '../../../../../data/repositories/citizen_repository.dart';
import '../../../../../data/repositories/emergency_repository.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/basic_widgets.dart';

String _formatJoinDate(DateTime date) {
  const months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];
  return '${months[date.month - 1]} de ${date.year}';
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _citizenRepository = CitizenRepository();
  final _emergencyRepository = EmergencyRepository();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<User> _loadUser() async {
    if (!AuthService.isLoggedIn.value) {
      throw const NeedsLoginException();
    }
    final citizen = await _citizenRepository.getProfile();
    final reports = await _emergencyRepository.listMineReports();
    final resolvedReports = reports.where((r) => r.status == ReportStatus.attended).length;
    return citizenToUser(
      citizen,
      totalReports: reports.length,
      activeReports: reports.length - resolvedReports,
      resolvedReports: resolvedReports,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundPrimary,
            body: Center(child: AppLoadingIndicator()),
          );
        }
        if (snapshot.hasError) {
          if (classifyLoadError(snapshot.error!) == LoadErrorKind.needsLogin) {
            return Scaffold(
              backgroundColor: AppColors.backgroundPrimary,
              body: Center(
                child: AppEmptyState(
                  icon: Icons.lock_outline,
                  title: 'Inicia sesión para ver tu perfil',
                  subtitle: 'Necesitas una cuenta para ver y gestionar tu perfil.',
                  action: AppButton(
                    label: 'Iniciar sesión',
                    isExpanded: false,
                    onPressed: AuthService.requestLogin,
                  ),
                ),
              ),
            );
          }
          return Scaffold(
            backgroundColor: AppColors.backgroundPrimary,
            body: Center(
              child: AppEmptyState(
                icon: Icons.error_outline,
                title: 'No se pudo cargar tu perfil',
                subtitle: 'Revisa tu conexión e intenta nuevamente.',
                action: AppButton(
                  label: 'Reintentar',
                  isExpanded: false,
                  onPressed: () => setState(() => _userFuture = _loadUser()),
                ),
              ),
            ),
          );
        }
        return _ProfileContent(user: snapshot.data!, onLogout: () => _showLogoutDialog(context));
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg)),
        title: Text('Cerrar sesión', style: AppTextStyles.headlineSmall),
        content: Text('¿Estás seguro de que quieres cerrar sesión?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: AppTextStyles.labelMedium),
          ),
          AppButton(
            label: 'Cerrar sesión',
            onPressed: () {
              Navigator.pop(context);
              AuthService.logout();
            },
            backgroundColor: AppColors.error,
            isExpanded: false,
          ),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final User user;
  final VoidCallback onLogout;

  const _ProfileContent({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.surfacePrimary,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.backgroundGradient,
                ),
                child: Stack(
                  children: [
                    const AppBackgroundPattern(color: AppColors.primaryBlue),
                    Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Hero(
                      tag: 'user_avatar',
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: AppTextStyles.displayMedium.copyWith(color: AppColors.textOnPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(user.name, style: AppTextStyles.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined, size: AppSpacing.iconSm, color: AppColors.textTertiary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(user.zone, style: AppTextStyles.bodyMediumSecondary),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Miembro desde ${_formatJoinDate(user.joinedAt)}', style: AppTextStyles.bodySmallTertiary),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildStatsRow(user),
                  const SizedBox(height: AppSpacing.xl),
                  _buildMenuSection('Mi actividad', [
                    _MenuItem(
                      icon: Icons.assignment_outlined,
                      title: 'Mis reportes',
                      subtitle: '${user.totalReports} reportes creados',
                      onTap: () => context.push('/reports/my'),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notificaciones',
                      subtitle: 'Alertas y actualizaciones',
                      onTap: () => context.push('/notifications'),
                    ),
                    _MenuItem(
                      icon: Icons.map_outlined,
                      title: 'Zonas favoritas',
                      subtitle: 'Gestionar áreas de interés',
                      onTap: () => context.push('/profile/favorite-zones'),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMenuSection('Preferencias', [
                    _MenuItem(
                      icon: Icons.tune_outlined,
                      title: 'Configuración',
                      subtitle: 'Personaliza la app',
                      onTap: () => context.push('/profile/settings'),
                    ),
                    _MenuItem(
                      icon: Icons.lock_outline,
                      title: 'Privacidad',
                      subtitle: 'Gestiona tus datos',
                      onTap: () => context.push('/profile/privacy'),
                    ),
                    _MenuItem(
                      icon: Icons.help_outline,
                      title: 'Ayuda y soporte',
                      subtitle: 'Preguntas frecuentes',
                      onTap: () => context.push('/profile/help'),
                    ),
                    _MenuItem(
                      icon: Icons.info_outline,
                      title: 'Acerca de',
                      subtitle: 'Versión 1.0.0',
                      onTap: () => context.push('/profile/about'),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMenuSection('Cuenta', [
                    _MenuItem(
                      icon: Icons.logout,
                      title: 'Cerrar sesión',
                      subtitle: 'Salir de tu cuenta',
                      isDestructive: true,
                      onTap: onLogout,
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(User user) {
    return Row(
      children: [
        Expanded(child: _buildStatItem(user.totalReports, 'Total reportes', Icons.assignment)),
        Container(width: 1, height: 48, color: AppColors.divider),
        Expanded(child: _buildStatItem(user.activeReports, 'En proceso', Icons.pending)),
        Container(width: 1, height: 48, color: AppColors.divider),
        Expanded(child: _buildStatItem(user.resolvedReports, 'Resueltos', Icons.check_circle)),
      ],
    ).immersiveEntrance();
  }

  Widget _buildStatItem(int value, String label, IconData icon) {
    return Column(
      children: [
        AppIconBadge(
          icon: icon,
          gradient: AppColors.primaryGradient,
          size: 40,
          iconSize: AppSpacing.iconMd,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCountUp(
          value: value,
          style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(label, style: AppTextStyles.bodySmallSecondary),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
            border: Border.all(color: AppColors.borderPrimary, width: 0.5),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _MenuTile(
                item: item,
                isFirst: index == 0,
                isLast: index == items.length - 1,
              ).staggerChild(index, step: const Duration(milliseconds: 50));
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  final bool isFirst;
  final bool isLast;

  const _MenuTile({
    super.key,
    required this.item,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppIconBadge(
        icon: item.icon,
        gradient: item.isDestructive ? AppColors.urgentGradient : AppColors.primaryGradient,
        size: 40,
        iconSize: AppSpacing.iconMd,
      ),
      title: Text(item.title, style: AppTextStyles.bodyLarge.copyWith(
        color: item.isDestructive ? AppColors.error : AppColors.textPrimary,
      )),
      subtitle: Text(item.subtitle, style: AppTextStyles.bodySmallSecondary),
      trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: item.onTap,
      shape: Border(
        bottom: isLast ? BorderSide.none : BorderSide(color: AppColors.divider, width: 0.5),
      ),
    );
  }
}