import 'package:flutter/material.dart';

enum IncidentType {
  theft('robo', 'Robo', Icons.shopping_bag_outlined),
  accident('accidente', 'Accidente', Icons.directions_car_outlined),
  suspiciousPerson('persona_sospechosa', 'Persona sospechosa', Icons.person_outline),
  violence('violencia', 'Violencia', Icons.warning_outlined),
  fire('incendio', 'Incendio', Icons.local_fire_department_outlined),
  medicalEmergency('emergencia_medica', 'Emergencia médica', Icons.local_hospital_outlined),
  vandalism('vandalismo', 'Vandalismo', Icons.broken_image_outlined),
  other('otro', 'Otro', Icons.help_outline);

  const IncidentType(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;
}

enum IncidentStatus {
  urgent('urgente', 'Urgente'),
  moderate('moderado', 'Moderado'),
  resolved('resuelto', 'Resuelto');

  const IncidentStatus(this.value, this.label);
  final String value;
  final String label;
}

enum ReportStatus {
  received('recibido', 'Recibido'),
  inReview('en_revision', 'En revisión'),
  attended('atendido', 'Atendido');

  const ReportStatus(this.value, this.label);
  final String value;
  final String label;
}

enum NotificationType {
  reportReceived('reporte_recibido', 'Reporte recibido'),
  reportInReview('reporte_en_revision', 'Reporte en revisión'),
  patrolAssigned('patrulla_asignada', 'Patrulla asignada'),
  incidentResolved('incidente_atendido', 'Incidente atendido');

  const NotificationType(this.value, this.label);
  final String value;
  final String label;
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String zone;
  final String avatarUrl;
  final int totalReports;
  final int activeReports;
  final int resolvedReports;
  final DateTime joinedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.zone,
    required this.avatarUrl,
    required this.totalReports,
    required this.activeReports,
    required this.resolvedReports,
    required this.joinedAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? zone,
    String? avatarUrl,
    int? totalReports,
    int? activeReports,
    int? resolvedReports,
    DateTime? joinedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      zone: zone ?? this.zone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalReports: totalReports ?? this.totalReports,
      activeReports: activeReports ?? this.activeReports,
      resolvedReports: resolvedReports ?? this.resolvedReports,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class Location {
  final double latitude;
  final double longitude;
  final String address;
  final String zone;
  final String reference;

  const Location({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.zone,
    this.reference = '',
  });

  Location copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? zone,
    String? reference,
  }) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      zone: zone ?? this.zone,
      reference: reference ?? this.reference,
    );
  }
}

class Incident {
  final String id;
  final String title;
  final String description;
  final IncidentType type;
  final IncidentStatus status;
  final Location location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String reporterId;
  final String reporterName;
  final List<String> evidenceUrls;
  final int viewsCount;
  final int confirmationsCount;
  final bool isNearby;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.reporterId,
    required this.reporterName,
    this.evidenceUrls = const [],
    this.viewsCount = 0,
    this.confirmationsCount = 0,
    this.isNearby = false,
  });

  Color get statusColor {
    switch (status) {
      case IncidentStatus.urgent:
        return const Color(0xFFFF5A38);
      case IncidentStatus.moderate:
        return const Color(0xFFFFB13C);
      case IncidentStatus.resolved:
        return const Color(0xFF33D9AE);
    }
  }

  String get statusLabel => status.label;
  String get typeLabel => type.label;
  IconData get typeIcon => type.icon;

  Incident copyWith({
    String? id,
    String? title,
    String? description,
    IncidentType? type,
    IncidentStatus? status,
    Location? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reporterId,
    String? reporterName,
    List<String>? evidenceUrls,
    int? viewsCount,
    int? confirmationsCount,
    bool? isNearby,
  }) {
    return Incident(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      viewsCount: viewsCount ?? this.viewsCount,
      confirmationsCount: confirmationsCount ?? this.confirmationsCount,
      isNearby: isNearby ?? this.isNearby,
    );
  }
}

class Report {
  final String id;
  final String title;
  final String description;
  final IncidentType type;
  final ReportStatus status;
  final Location location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> evidenceUrls;
  final List<TimelineEvent> timeline;

  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    this.evidenceUrls = const [],
    this.timeline = const [],
  });

  String get statusLabel => status.label;
  String get typeLabel => type.label;
  IconData get typeIcon => type.icon;

  Report copyWith({
    String? id,
    String? title,
    String? description,
    IncidentType? type,
    ReportStatus? status,
    Location? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? evidenceUrls,
    List<TimelineEvent>? timeline,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      timeline: timeline ?? this.timeline,
    );
  }
}

class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;
  final bool isCurrent;
  final IconData icon;
  final Color color;

  const TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isCompleted,
    required this.isCurrent,
    required this.icon,
    required this.color,
  });
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedReportId;
  final String? relatedIncidentId;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.relatedReportId,
    this.relatedIncidentId,
  });

  String get typeLabel => type.label;

  NotificationItem copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? relatedReportId,
    String? relatedIncidentId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedReportId: relatedReportId ?? this.relatedReportId,
      relatedIncidentId: relatedIncidentId ?? this.relatedIncidentId,
    );
  }
}

class IncidentCategory {
  final IncidentType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Gradient gradient;

  const IncidentCategory({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}