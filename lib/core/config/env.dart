/// Build-time configuration read via `--dart-define`/`--dart-define-from-file`
/// (see `env.json.example`) so secrets never get hardcoded into source.
class Env {
  Env._();

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;
}
