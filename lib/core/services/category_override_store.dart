import 'package:shared_preferences/shared_preferences.dart';

/// The citizen-facing report endpoint (`POST /api/citizen/emergency/report`)
/// has no category field — the backend assigns `tbemergencytypes` itself and
/// defaults every new report to "Otro" until (if ever) its own classification
/// runs. So a category chosen client-side, by the voice assistant or the
/// manual wizard, has nowhere server-side to go.
///
/// This stores that choice locally, keyed by emergency id, so this device's
/// own map/report list can show the real category immediately instead of
/// "Otro" — see [emergencyToIncident]/[emergencyToReport] in mappers.dart,
/// which prefer this over `dto.type.code` when present. It's a per-device
/// cosmetic override, not synced anywhere: a reinstall or a different device
/// will show whatever the backend itself has on file.
class CategoryOverrideStore {
  CategoryOverrideStore._();

  static const String _prefix = 'category_override_';

  static Future<void> save(int emergencyId, String typeValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$emergencyId', typeValue);
  }

  static Future<Map<int, String>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <int, String>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final id = int.tryParse(key.substring(_prefix.length));
      final value = prefs.getString(key);
      if (id != null && value != null) result[id] = value;
    }
    return result;
  }
}
