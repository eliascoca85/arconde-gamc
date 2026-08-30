import 'package:intl/intl.dart';

class Formatters {
  static String formatTime(DateTime dateTime, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern).format(dateTime);
  }

  static String formatDate(DateTime dateTime, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern).format(dateTime);
  }

  static String formatDateTime(DateTime dateTime, {String pattern = 'dd/MM/yyyy HH:mm'}) {
    return DateFormat(pattern).format(dateTime);
  }

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Ahora mismo';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return formatDate(dateTime);
    }
  }

  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map(capitalize).join(' ');
  }

  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  static String formatIncidentType(String type) {
    switch (type) {
      case 'robo':
        return 'Robo';
      case 'accidente':
        return 'Accidente';
      case 'persona_sospechosa':
        return 'Persona sospechosa';
      case 'violencia':
        return 'Violencia';
      case 'incendio':
        return 'Incendio';
      case 'emergencia_medica':
        return 'Emergencia médica';
      case 'vandalismo':
        return 'Vandalismo';
      case 'otro':
        return 'Otro';
      default:
        return capitalizeWords(type.replaceAll('_', ' '));
    }
  }

  static String formatIncidentStatus(String status) {
    switch (status) {
      case 'urgente':
        return 'Urgente';
      case 'moderado':
        return 'Moderado';
      case 'resuelto':
        return 'Resuelto';
      default:
        return capitalize(status);
    }
  }

  static String formatReportStatus(String status) {
    switch (status) {
      case 'recibido':
        return 'Recibido';
      case 'en_revision':
        return 'En revisión';
      case 'atendido':
        return 'Atendido';
      default:
        return capitalize(status.replaceAll('_', ' '));
    }
  }

  static String formatNotificationType(String type) {
    switch (type) {
      case 'reporte_recibido':
        return 'Reporte recibido';
      case 'reporte_en_revision':
        return 'Reporte en revisión';
      case 'patrulla_asignada':
        return 'Patrulla asignada';
      case 'incidente_atendido':
        return 'Incidente atendido';
      default:
        return capitalizeWords(type.replaceAll('_', ' '));
    }
  }
}