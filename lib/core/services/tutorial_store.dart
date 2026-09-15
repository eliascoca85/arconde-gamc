import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which onboarding coach mark tours the user has already completed
/// (or skipped), by device, so a tour like the home screen's main-buttons
/// guide only ever shows once per install instead of on every app open.
class TutorialStore {
  TutorialStore._();

  static const _keyHomeTourSeen = 'tutorial_home_tour_seen_v1';

  static Future<bool> hasSeenHomeTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHomeTourSeen) ?? false;
  }

  static Future<void> setHomeTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHomeTourSeen, true);
  }
}
