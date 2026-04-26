import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';

class ApiClient {
  ApiClient._()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

  final Dio dio;

  static final ApiClient instance = ApiClient._();
}
