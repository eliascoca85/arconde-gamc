import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  static const _prefsKeyLoggedIn = 'is_logged_in';
  static const _prefsKeyCitizenId = 'citizen_id';

  static final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  static int? currentCitizenId;

  /// Bumped whenever a "skipped auth" user tries to do something that
  /// requires an account, so the top-level app shell can bring back the
  /// login/register screen. A counter (not a bool) so repeated requests
  /// after a cancelled login still notify listeners.
  static final ValueNotifier<int> loginRequests = ValueNotifier<int>(0);

  static void requestLogin() => loginRequests.value++;

  static Future<void> restoreSession() async {
    await ApiClient.instance.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final wasLoggedIn = prefs.getBool(_prefsKeyLoggedIn) ?? false;
    if (!wasLoggedIn) {
      isLoggedIn.value = false;
      return;
    }

    try {
      final response = await ApiClient.instance.dio.get('/api/citizen/profile');
      if (response.statusCode == 200) {
        currentCitizenId = prefs.getInt(_prefsKeyCitizenId);
        isLoggedIn.value = true;
        return;
      }
    } catch (_) {
      // fall through to clear session
    }

    await _clearLocalSession(prefs);
    isLoggedIn.value = false;
  }

  static Future<void> login(String phoneNumber, String password) async {
    await ApiClient.instance.ensureInitialized();
    final dio = ApiClient.instance.dio;

    final csrfResponse = await dio.get('/api/auth/csrf');
    final csrfToken = csrfResponse.data is Map ? csrfResponse.data['csrfToken'] as String? : null;
    if (csrfToken == null) {
      throw AuthException('No se pudo iniciar sesión. Intenta nuevamente.');
    }

    await dio.post(
      '/api/auth/callback/citizen',
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
        'csrfToken': csrfToken,
      },
      options: Options(
        validateStatus: (status) => status != null && status < 500,
        followRedirects: true,
      ),
    );

    Map<String, dynamic>? profile;
    try {
      final profileResponse = await dio.get('/api/citizen/profile');
      if (profileResponse.statusCode == 200) {
        profile = profileResponse.data as Map<String, dynamic>;
      }
    } catch (_) {
      // treated as failure below
    }

    if (profile == null) {
      throw AuthException('Número de celular o contraseña incorrectos.');
    }

    final citizen = profile['citizen'] as Map<String, dynamic>?;
    final citizenId = citizen != null ? citizen['PK_citizen'] as int? : null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyLoggedIn, true);
    if (citizenId != null) {
      await prefs.setInt(_prefsKeyCitizenId, citizenId);
    }
    currentCitizenId = citizenId;
    isLoggedIn.value = true;
  }

  static Future<void> register({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String password,
    String? ci,
    String? email,
  }) async {
    await ApiClient.instance.ensureInitialized();
    final dio = ApiClient.instance.dio;

    try {
      await dio.post(
        '/api/citizens',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'password': password,
          if (ci != null && ci.isNotEmpty) 'CI': ci,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['error'] ?? e.response?.data['message'])?.toString()
          : null;
      throw AuthException(message ?? 'No se pudo crear la cuenta. Intenta nuevamente.');
    }

    await login(phoneNumber, password);
  }

  static Future<void> logout() async {
    await ApiClient.instance.clearCookies();
    final prefs = await SharedPreferences.getInstance();
    await _clearLocalSession(prefs);
    currentCitizenId = null;
    isLoggedIn.value = false;
  }

  static Future<void> _clearLocalSession(SharedPreferences prefs) async {
    await prefs.remove(_prefsKeyLoggedIn);
    await prefs.remove(_prefsKeyCitizenId);
  }
}
