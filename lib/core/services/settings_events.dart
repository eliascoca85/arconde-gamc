import 'package:flutter/foundation.dart';

/// Fires whenever the saved favorite zones change, so an already-mounted
/// screen showing them (Inicio's quick-select chips) can reload in place
/// instead of requiring the user to leave and reopen the app to see it.
class SettingsEvents {
  SettingsEvents._();

  static final ValueNotifier<int> favoriteZonesChanged = ValueNotifier<int>(0);

  static void notifyFavoriteZonesChanged() {
    favoriteZonesChanged.value++;
  }
}
