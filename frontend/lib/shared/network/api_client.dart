import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';

class ApiClient {
  ApiClient._()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

  final Dio dio;
  String? _token;

  void setSessionToken(String? token) {
    _token = token;
    if (token == null) {
      dio.options.headers.remove('Authorization');
    } else {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  String? get sessionToken => _token;

  static final ApiClient instance = ApiClient._();
}
