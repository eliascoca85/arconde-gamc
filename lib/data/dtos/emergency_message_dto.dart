class EmergencyMessageDto {
  final int pkChatMessage;
  final String senderRole;
  final String senderName;
  final String messageType;
  final String message;
  final String? fileUrl;
  final DateTime createdAt;

  EmergencyMessageDto({
    required this.pkChatMessage,
    required this.senderRole,
    required this.senderName,
    required this.messageType,
    required this.message,
    this.fileUrl,
    required this.createdAt,
  });

  factory EmergencyMessageDto.fromJson(Map<String, dynamic> json) {
    return EmergencyMessageDto(
      pkChatMessage: json['PK_chatMessage'] as int,
      senderRole: json['senderRole'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      messageType: json['messageType'] as String? ?? 'TEXT',
      message: json['message'] as String? ?? '',
      fileUrl: json['fileUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
