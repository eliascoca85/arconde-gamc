import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

void configureWebCookies(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}
