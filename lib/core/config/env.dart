/// Build-time configuration read via `--dart-define`/`--dart-define-from-file`
/// (see `env.json.example`) so secrets never get hardcoded into source.
class Env {
  Env._();

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;

  /// Backend host. Defaults to production (Vercel) so a plain `flutter run`
  /// never accidentally talks to a developer's laptop. Override locally via
  /// `API_BASE_URL` in `env.json` — e.g. `http://10.0.2.2:3000` for the
  /// Android emulator, `http://localhost:3000` for the iOS simulator, or
  /// your machine's LAN IP for a physical device on the same network.
  ///
  /// `env.json.example` ships this key blank, and blank must still mean
  /// "use production" — `String.fromEnvironment`'s `defaultValue` only
  /// applies when the key is entirely absent, not when it's defined as "",
  /// so the fallback is handled explicitly here instead.
  static const String _rawApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl =>
      _rawApiBaseUrl.isEmpty ? 'https://sos-24-gamc.vercel.app' : _rawApiBaseUrl;
}
