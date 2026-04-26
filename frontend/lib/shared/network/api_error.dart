import 'package:dio/dio.dart';

String friendlyApiError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }

    switch (status) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Session expired. Please sign in again.';
      case 403:
        return 'You are not allowed to perform this action.';
      case 404:
        return 'Requested resource was not found.';
      case 409:
        return 'Conflict detected. Please refresh and try again.';
      case 413:
        return 'File is too large for upload.';
      case 422:
        return 'Submitted data could not be processed.';
      case 429:
        return 'Too many requests. Please wait a moment and retry.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server is temporarily unavailable. Please try again.';
      default:
        break;
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Network timeout. Please check your connection and retry.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to server. Please check your internet/tunnel.';
    }
    if (error.type == DioExceptionType.cancel) {
      return 'Request was cancelled.';
    }
  }

  final raw = error.toString();
  if (raw.length > 240) return raw.substring(0, 240);
  return raw;
}
