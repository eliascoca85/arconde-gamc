class AppConstants {
  static const String appName = 'Arconte';
  static const String appTagline = 'Tu comunidad, tu seguridad';

  static const String mockUserId = 'user_001';
  static const String mockUserName = 'Carlos Mendoza';
  static const String mockUserZone = 'Cochabamba · Zona Norte';
  static const String mockUserAvatar = 'assets/images/avatar_placeholder.png';

  static const double defaultMapZoom = 15.0;
  static const double defaultMapLatitude = -17.3895;
  static const double defaultMapLongitude = -66.1568;

  static const int maxReportDescriptionLength = 500;
  static const int maxReportTitleLength = 100;

  static const Duration defaultAnimationDuration = Duration(milliseconds: 250);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);

  static const String incidentTypeTheft = 'robo';
  static const String incidentTypeAccident = 'accidente';
  static const String incidentTypeSuspicious = 'persona_sospechosa';
  static const String incidentTypeViolence = 'violencia';
  static const String incidentTypeFire = 'incendio';
  static const String incidentTypeMedical = 'emergencia_medica';
  static const String incidentTypeVandalism = 'vandalismo';
  static const String incidentTypeOther = 'otro';

  static const String incidentStatusUrgent = 'urgente';
  static const String incidentStatusModerate = 'moderado';
  static const String incidentStatusResolved = 'resuelto';

  static const String reportStatusReceived = 'recibido';
  static const String reportStatusInReview = 'en_revision';
  static const String reportStatusAttended = 'atendido';

  static const String notificationTypeReportReceived = 'reporte_recibido';
  static const String notificationTypeReportInReview = 'reporte_en_revision';
  static const String notificationTypePatrolAssigned = 'patrulla_asignada';
  static const String notificationTypeIncidentResolved = 'incidente_atendido';
}