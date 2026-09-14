import 'package:dio/dio.dart';
import 'auth_service.dart';

/// Se lanza cuando una pantalla decide, antes de siquiera llamar a la API,
/// que hace falta una cuenta para cargar sus datos (modo invitado).
class NeedsLoginException implements Exception {
  const NeedsLoginException();
}

enum LoadErrorKind { needsLogin, noConnection, unknown }

const _connectivityTypes = {
  DioExceptionType.connectionError,
  DioExceptionType.connectionTimeout,
  DioExceptionType.receiveTimeout,
  DioExceptionType.sendTimeout,
};

/// Distingue, para el estado de error de una pantalla, si hace falta iniciar
/// sesión, si es un problema de conexión, o algo genérico — para no mostrarle
/// "revisa tu conexión" a alguien que simplemente no se ha logeado.
LoadErrorKind classifyLoadError(Object error) {
  if (error is NeedsLoginException) return LoadErrorKind.needsLogin;
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) return LoadErrorKind.needsLogin;
    if (_connectivityTypes.contains(error.type)) return LoadErrorKind.noConnection;
  }
  if (!AuthService.isLoggedIn.value) return LoadErrorKind.needsLogin;
  return LoadErrorKind.unknown;
}
