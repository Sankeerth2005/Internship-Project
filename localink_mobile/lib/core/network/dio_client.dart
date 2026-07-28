import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage_service.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;

  // 💡 CONFIGURATION FOR EXTERNAL DEVICE / EMULATOR:
  // - For Android Emulator: Use '10.0.2.2'
  // - For Physical Device (USB Debugging): Run `adb reverse tcp:5138 tcp:5138` on your computer terminal and change this to '127.0.0.1'
  // - For Physical Device (same Wi-Fi): Change this to your computer's local IP (e.g., '192.168.1.15')
  // - For Testing with ngrok: Use ngrok URL for external access
  static const String backendHost = 'bulldog-kinsman-tutor.ngrok-free.dev';
  static const bool useHttps = true;
  static const int backendPort = 443;
  static VoidCallback? onUnauthorized;
  static VoidCallback? onRateLimited;

  /// Resolves a potentially relative URL (e.g. `/uploads/abc.jpg`) to an absolute URL
  /// using the backend base URL origin.
  static String? resolveUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      // Already an absolute URL with scheme (http://, https://)
      return value;
    }

    // Build the backend origin from the configured host
    final scheme = useHttps ? 'https' : 'http';
    final port = (useHttps && backendPort == 443) ? '' : ':$backendPort';
    final origin = '$scheme://$backendHost$port';
    return value.startsWith('/') ? '$origin$value' : '$origin/$value';
  }

  /// Returns the backend origin (scheme + host + port) for building image URLs
  static String get backendOrigin {
    final scheme = useHttps ? 'https' : 'http';
    final port = (useHttps && backendPort == 443) ? '' : ':$backendPort';
    return '$scheme://$backendHost$port';
  }

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    // Use ngrok URL for external testing
    final scheme = useHttps ? 'https' : 'http';
    final port = (useHttps && backendPort == 443) ? '' : ':$backendPort';
    String baseUrlStr = '$scheme://$backendHost$port/api/v1/';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrlStr,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final hasAuthorizationHeader = options.headers.keys.any(
            (key) => key.toString().toLowerCase() == 'authorization',
          );

          if (!hasAuthorizationHeader) {
            final token = await SecureStorageService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },
        onError: (DioException e, handler) async {
          final isLoginRequest = e.requestOptions.path.contains('sessions');
          if (e.response?.statusCode == 401 && !isLoginRequest) {
            onUnauthorized?.call();
          } else if (e.response?.statusCode == 429) {
            onRateLimited?.call();
          }
          return handler.next(e);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(responseBody: true, requestBody: true),
    );
  }

  Dio get dio => _dio;
}