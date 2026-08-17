import 'package:dio/dio.dart';

class AppErrorFormatter {
  static bool isOfflineError(dynamic error) {
    if (error is! DioException) return false;
    if (error.type == DioExceptionType.connectionError) return true;
    if (error.type == DioExceptionType.unknown) {
      final message = error.message ?? '';
      return message.contains('SocketException') ||
          message.contains('Network is unreachable') ||
          message.contains('Failed host lookup');
    }
    return false;
  }

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
          return 'No internet connection. Please check your network and try again.';
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
              final fieldErrors = validationMessages(data);
              if (fieldErrors != null && fieldErrors.isNotEmpty) {
                return fieldErrors;
              }
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
          if (message != null &&
              (message.contains('SocketException') ||
                  message.contains('Network is unreachable') ||
                  message.contains('Failed host lookup'))) {
            return 'No internet connection. Please check your network and try again.';
          }
          return message ?? 'An unknown connection error occurred. Please try again.';
      }
    }

    final errString = error.toString();
    if (errString.startsWith('Exception: ')) {
      return errString.substring(11);
    }
    return errString;
  }

  /// Reads ASP.NET ProblemDetails / custom `{ errors: ... }` payloads so the
  /// UI can show the failing field instead of "One or more validation errors occurred."
  static String? validationMessages(Map data) {
    final errors = data['errors'];
    final messages = <String>[];

    if (errors is Map) {
      for (final value in errors.values) {
        _collectErrorValue(value, messages);
      }
    } else if (errors is List) {
      for (final item in errors) {
        _collectErrorValue(item, messages);
      }
    }

    if (messages.isEmpty) return null;
    return messages.join('\n');
  }

  static void _collectErrorValue(dynamic value, List<String> messages) {
    if (value == null) return;
    if (value is List) {
      for (final item in value) {
        _collectErrorValue(item, messages);
      }
      return;
    }
    if (value is Map) {
      final nested = value['errors'] ?? value['error'] ?? value['message'];
      if (nested != null) {
        _collectErrorValue(nested, messages);
        return;
      }
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) messages.add(text);
  }
}
