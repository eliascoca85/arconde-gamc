import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centraliza el pedido de permisos sensibles (micrófono, cámara, ubicación).
///
/// - [hasCompletedInitialOnboarding] / [requestInitialPermissions] /
///   [markInitialOnboardingSkipped] respaldan la pantalla de onboarding
///   (`PermissionsRequestPage`), que se muestra una sola vez en la vida de la
///   instalación, justo después de que carga la primera vista de la app, y
///   pide de golpe los permisos que la app usa. Nunca se vuelve a mostrar
///   después de esa primera vez, el usuario haya concedido los permisos o
///   los haya saltado.
/// - Aparte de eso, cada función que de verdad necesita un permiso sigue
///   pidiéndolo puntualmente si todavía no fue concedido (eso ya ocurre hoy:
///   `ai_report_page.dart` pide micrófono antes de grabar, `location_service`
///   pide ubicación antes de geolocalizar, e `image_picker` dispara el
///   diálogo nativo de cámara/galería al tomar una foto). [ensureGranted]
///   queda disponible para nuevos puntos on-demand que quieran el mismo
///   patrón de "pedir solo si hace falta".
class PermissionService {
  PermissionService._();

  static const _prefsKeyRequestedInitial = 'permissions_requested_initial';

  /// Si ya se mostró (y resolvió, de cualquier forma) el onboarding de
  /// permisos alguna vez en esta instalación.
  static Future<bool> hasCompletedInitialOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKeyRequestedInitial) ?? false;
  }

  /// Pide de una vez ubicación, micrófono y cámara, y marca el onboarding
  /// como completado (con cualquier resultado, se hayan concedido o no).
  static Future<void> requestInitialPermissions() async {
    try {
      await [
        Permission.locationWhenInUse,
        Permission.microphone,
        Permission.camera,
      ].request();
    } catch (_) {
      // Si el plugin falla (plataforma no soportada, canal no disponible,
      // etc.) no bloqueamos el flujo — los pedidos puntuales de cada función
      // siguen funcionando como respaldo.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyRequestedInitial, true);
  }

  /// El usuario eligió "Ahora no" en el onboarding: no se pide nada, pero
  /// tampoco se le vuelve a mostrar la pantalla en el futuro.
  static Future<void> markInitialOnboardingSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyRequestedInitial, true);
  }

  /// Pide un permiso puntual solo si todavía no fue concedido. Devuelve
  /// `true` si al terminar el permiso queda concedido.
  static Future<bool> ensureGranted(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) return true;
    final result = await permission.request();
    return result.isGranted;
  }
}
