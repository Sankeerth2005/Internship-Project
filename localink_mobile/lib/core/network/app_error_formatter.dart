import 'package:dio/dio.dart';

class AppErrorFormatter {
  static String format(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
          return 'Connection timed out. Please check your internet connection and try again.';
        case DioExceptionType.receiveTimeout:
          return 'The server took too long to respond. Please try again later.';
        case DioExceptionType.connectionError:
          return 'Server is unreachable. Please verify your internet connection or try again later.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.badCertificate:
          return 'A secure connection could not be established.';
        case DioExceptionType.badResponse:
          final response = error.response;
          if (response != null) {
            final statusCode = response.statusCode;
            final data = response.data;

            if (statusCode == 401) {
              return 'Invalid credentials. Please verify your email and password and try again.';
            } else if (statusCode == 403) {
              return 'You do not have permission to perform this action.';
            } else if (statusCode == 404) {
              return 'The requested resource was not found.';
            } else if (statusCode == 429) {
              return 'Too many requests. Please wait a moment and try again.';
            } else if (statusCode != null && statusCode >= 500) {
              return 'Server error ($statusCode). We are working to resolve this. Please try again later.';
            }

            if (data is Map) {
              final message = data['message'] ?? data['title'] ?? data['error'];
              if (message != null && message.toString().isNotEmpty) {
                return message.toString();
              }
            }
          }
          return 'Server returned an invalid response. Please try again.';
        case DioExceptionType.unknown:
        default:
          final message = error.message;
          if (message != null && message.contains('SocketException')) {
            return 'No internet connection. Please check your network and try again.';
          }
          return message ?? 'An unknown connection error occurred. Please try again.';
      }
    }

    // Standard Exceptions/Errors
    final errString = error.toString();
    if (errString.startsWith('Exception: ')) {
      return errString.substring(11);
    }
    return errString;
  }
}
