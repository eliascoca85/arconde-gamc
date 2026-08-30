class NotificationDto {
  final int pkNotification;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;
  final int? fkEmergency;

  NotificationDto({
    required this.pkNotification,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    this.fkEmergency,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      pkNotification: json['PK_notification'] as int,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      notificationType: json['notificationType'] as String? ?? 'SYSTEM_ALERT',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      fkEmergency: json['FK_emergency'] as int?,
    );
  }
}
