import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../config/env.dart';
import 'api_client_platform_stub.dart'
  if (dart.library.js_interop) 'api_client_platform_web.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static final String baseUrl = Env.apiBaseUrl;

  late final Dio dio = _createDio();

  Dio _createDio() {
    final client = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    configureWebCookies(client);
    return client;
  }

  PersistCookieJar? _cookieJar;
  Future<void>? _initFuture;

  Future<void> ensureInitialized() {
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    if (kIsWeb) return;
    final dir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage('${dir.path}/.cookies/'),
    );
    dio.interceptors.add(CookieManager(_cookieJar!));
  }

  Future<void> clearCookies() async {
    await ensureInitialized();
    await _cookieJar?.deleteAll();
  }
}
