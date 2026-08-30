import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../mock/models.dart';
import 'dtos/citizen_dto.dart';
import 'dtos/emergency_dto.dart';
import 'dtos/notification_dto.dart';

IncidentType _incidentTypeFromCode(String code) {
  final value = code.toLowerCase();
  for (final type in IncidentType.values) {
    if (type.value == value) return type;
  }
  return IncidentType.other;
}

IncidentStatus _incidentStatusFrom(String priority, String status) {
  const resolvedStatuses = {'RESUELTA', 'FALSA_ALARMA', 'CANCELADA'};
  if (resolvedStatuses.contains(status)) return IncidentStatus.resolved;

  switch (priority) {
    case 'CRITICA':
    case 'ALTA':
      return IncidentStatus.urgent;
    case 'MEDIA':
    case 'BAJA':
    default:
      return IncidentStatus.moderate;
  }
}

ReportStatus _reportStatusFrom(String status) {
  const receivedStatuses = {'REPORTADA', 'EN_ANALISIS', 'CLASIFICADA'};
  const inReviewStatuses = {'ASIGNADA', 'EN_ATENCION'};

  if (receivedStatuses.contains(status)) return ReportStatus.received;
  if (inReviewStatuses.contains(status)) return ReportStatus.inReview;
  return ReportStatus.attended;
}

Location _locationFromDto(EmergencyDto dto) {
  if (dto.locations.isEmpty) {
    return const Location(
      latitude: AppConstants.defaultMapLatitude,
      longitude: AppConstants.defaultMapLongitude,
      address: 'Ubicación no disponible',
      zone: '',
    );
  }

  final loc = dto.locations.first;
  return Location(
    latitude: loc.latitude,
    longitude: loc.longitude,
    address: loc.address ?? 'Sin dirección',
    zone: '',
  );
}

String _titleFromDto(EmergencyDto dto) => dto.type.name;

List<TimelineEvent> _timelineFromDto(EmergencyDto dto) {
  final status = _reportStatusFrom(dto.status);

  return [
    TimelineEvent(
      id: 'tl_${dto.pkEmergency}_1',
      title: 'Recibido',
      description: 'Reporte registrado en el sistema',
      timestamp: dto.reportedAt,
      isCompleted: true,
      isCurrent: status == ReportStatus.received,
      icon: Icons.check_circle,
      color: AppColors.resolvedGreen,
    ),
    TimelineEvent(
      id: 'tl_${dto.pkEmergency}_2',
      title: 'En revisión',
      description: dto.assignments.isNotEmpty
          ? 'Unidad asignada: ${dto.assignments.first.unit?.unitName ?? dto.assignments.first.institution?.name ?? ''}'
          : 'Pendiente asignación',
      timestamp: dto.reportedAt,
      isCompleted: status == ReportStatus.inReview || status == ReportStatus.attended,
      isCurrent: status == ReportStatus.inReview,
      icon: Icons.local_police,
      color: AppColors.primaryBlue,
    ),
    TimelineEvent(
      id: 'tl_${dto.pkEmergency}_3',
      title: 'Atendido',
      description: status == ReportStatus.attended
          ? 'Emergencia atendida'
          : 'Pendiente',
      timestamp: dto.resolvedAt ?? dto.updatedAt,
      isCompleted: status == ReportStatus.attended,
      isCurrent: status == ReportStatus.attended,
      icon: Icons.verified,
      color: AppColors.resolvedGreen,
    ),
  ];
}

Incident emergencyToIncident(
  EmergencyDto dto, {
  required String reporterId,
  required String reporterName,
  String? typeOverride,
}) {
  return Incident(
    id: dto.pkEmergency.toString(),
    title: _titleFromDto(dto),
    description: dto.description,
    type: _incidentTypeFromCode(typeOverride ?? dto.type.code),
    status: _incidentStatusFrom(dto.priority, dto.status),
    location: _locationFromDto(dto),
    createdAt: dto.createdAt,
    updatedAt: dto.resolvedAt ?? dto.updatedAt,
    reporterId: reporterId,
    reporterName: reporterName,
    evidenceUrls: const [],
    viewsCount: 0,
    confirmationsCount: dto.assignments.length,
    isNearby: true,
  );
}

Report emergencyToReport(EmergencyDto dto, {String? typeOverride}) {
  return Report(
    id: dto.pkEmergency.toString(),
    title: _titleFromDto(dto),
    description: dto.description,
    type: _incidentTypeFromCode(typeOverride ?? dto.type.code),
    status: _reportStatusFrom(dto.status),
    location: _locationFromDto(dto),
    createdAt: dto.createdAt,
    updatedAt: dto.resolvedAt ?? dto.updatedAt,
    evidenceUrls: const [],
    timeline: _timelineFromDto(dto),
  );
}

User citizenToUser(
  CitizenDto dto, {
  required int totalReports,
  required int activeReports,
  required int resolvedReports,
}) {
  return User(
    id: dto.pkCitizen.toString(),
    name: dto.fullName,
    email: dto.email ?? '',
    phone: dto.phoneNumber,
    zone: '',
    avatarUrl: dto.profileImage ?? '',
    totalReports: totalReports,
    activeReports: activeReports,
    resolvedReports: resolvedReports,
    joinedAt: dto.createdAt,
  );
}

NotificationType _notificationTypeFrom(String title, String message) {
  final text = '$title $message'.toLowerCase();
  if (text.contains('unidad') || text.contains('patrulla') || text.contains('asignad')) {
    return NotificationType.patrolAssigned;
  }
  if (text.contains('resuelt') || text.contains('atendid') || text.contains('llegó') || text.contains('lleg')) {
    return NotificationType.incidentResolved;
  }
  if (text.contains('revis') || text.contains('análisis') || text.contains('analisis')) {
    return NotificationType.reportInReview;
  }
  return NotificationType.reportReceived;
}

NotificationItem notificationDtoToNotificationItem(NotificationDto dto) {
  return NotificationItem(
    id: dto.pkNotification.toString(),
    type: _notificationTypeFrom(dto.title, dto.message),
    title: dto.title,
    message: dto.message,
    timestamp: dto.createdAt,
    isRead: dto.isRead,
    relatedIncidentId: dto.fkEmergency?.toString(),
  );
}
