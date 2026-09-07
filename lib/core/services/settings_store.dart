import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A saved favorite zone — a bookmark of a real Nominatim search result
/// (see [NominatimService]), stored by its stable OSM id so it can be
/// re-resolved with full geometry later via [NominatimService.lookup],
/// without re-running a text search against a name that may have drifted.
class FavoriteZone {
  final String osmType;
  final int osmId;
  final String primaryLabel;
  final String secondaryLabel;
  final double lat;
  final double lon;

  const FavoriteZone({
    required this.osmType,
    required this.osmId,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.lat,
    required this.lon,
  });

  String get key => '$osmType/$osmId';

  Map<String, dynamic> toJson() => {
        'osmType': osmType,
        'osmId': osmId,
        'primaryLabel': primaryLabel,
        'secondaryLabel': secondaryLabel,
        'lat': lat,
        'lon': lon,
      };

  static FavoriteZone? fromJson(Map<String, dynamic> json) {
    final osmType = json['osmType'] as String?;
    final osmId = json['osmId'] as int?;
    final primaryLabel = json['primaryLabel'] as String?;
    final lat = (json['lat'] as num?)?.toDouble();
    final lon = (json['lon'] as num?)?.toDouble();
    if (osmType == null || osmId == null || primaryLabel == null || lat == null || lon == null) {
      return null;
    }
    return FavoriteZone(
      osmType: osmType,
      osmId: osmId,
      primaryLabel: primaryLabel,
      secondaryLabel: json['secondaryLabel'] as String? ?? '',
      lat: lat,
      lon: lon,
    );
  }
}

/// Preferencias locales de la app (zonas favoritas, notificaciones). Todo
/// esto es por-dispositivo — no se sincroniza con el backend — respaldando
/// las pantallas de "Zonas favoritas" y "Configuración" del perfil.
class SettingsStore {
  SettingsStore._();

  static const _keyFavoriteZones = 'favorite_zones_v2';
  static const _keyNotifyReportUpdates = 'notify_report_updates';

  static Future<List<FavoriteZone>> loadFavoriteZones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyFavoriteZones) ?? const [];
    final zones = <FavoriteZone>[];
    for (final entry in raw) {
      try {
        final zone = FavoriteZone.fromJson(jsonDecode(entry) as Map<String, dynamic>);
        if (zone != null) zones.add(zone);
      } catch (_) {
        continue;
      }
    }
    return zones;
  }

  static Future<void> setFavoriteZones(List<FavoriteZone> zones) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavoriteZones, zones.map((z) => jsonEncode(z.toJson())).toList());
  }

  /// Si las notificaciones de cambios en reportes están activas. Ver
  /// [NotificationsPage], que revisa esto antes de cargar la lista.
  static Future<bool> loadNotifyReportUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifyReportUpdates) ?? true;
  }

  static Future<void> setNotifyReportUpdates(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifyReportUpdates, value);
  }

  /// Borra las preferencias locales de la app (favoritos, notificaciones,
  /// overrides de categoría) — usado desde "Privacidad". No toca la sesión;
  /// cerrar sesión es una acción aparte.
  static Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFavoriteZones);
    await prefs.remove(_keyNotifyReportUpdates);
    for (final key in prefs.getKeys().where((k) => k.startsWith('category_override_')).toList()) {
      await prefs.remove(key);
    }
  }
}
