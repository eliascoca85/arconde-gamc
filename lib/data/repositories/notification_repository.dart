import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../mock/models.dart';
import '../dtos/notification_dto.dart';
import '../mappers.dart';

class NotificationRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<NotificationItem>> list() async {
    final response = await _dio.get('/api/citizen/notifications');
    final dtos = (response.data['notifications'] as List<dynamic>)
        .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return dtos.map(notificationDtoToNotificationItem).toList();
  }

  Future<void> markRead(int notificationId) async {
    await _dio.put(
      '/api/citizen/notifications',
      data: {'PK_notification': notificationId},
    );
  }

  Future<void> markAllRead() async {
    await _dio.put(
      '/api/citizen/notifications',
      data: {'markAllAsRead': true},
    );
  }
}
