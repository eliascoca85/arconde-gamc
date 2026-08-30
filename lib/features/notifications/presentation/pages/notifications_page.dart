import 'package:flutter/material.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../data/repositories/notification_repository.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/components/notification_card.dart';
import '../../../../../shared/widgets/basic_widgets.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _notificationRepository = NotificationRepository();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final notifications = await _notificationRepository.list();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;
    setState(() {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    });
    try {
      await _notificationRepository.markRead(int.parse(id));
    } catch (_) {
      // Local state already reflects read; a background retry isn't worth surfacing here.
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    try {
      await _notificationRepository.markAllRead();
    } catch (_) {
      // Local state already reflects read; a background retry isn't worth surfacing here.
    }
  }

  void _dismissNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Notificaciones', style: AppTextStyles.titleLarge),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text('Marcar todo como leído', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryBlue)),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
    }
    if (_hasError) {
      return Center(
        child: AppEmptyState(
          icon: Icons.error_outline,
          title: 'No se pudieron cargar tus notificaciones',
          subtitle: 'Revisa tu conexión e intenta nuevamente.',
          action: AppButton(
            label: 'Reintentar',
            isExpanded: false,
            onPressed: _loadNotifications,
          ),
        ),
      );
    }
    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () {
              _markAsRead(notification.id);
              // Navigate to related content
            },
            onDismiss: () => _dismissNotification(notification.id),
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_none_outlined, size: AppSpacing.iconXl, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Sin notificaciones', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('Cuando haya novedades, aparecerán aquí', style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}