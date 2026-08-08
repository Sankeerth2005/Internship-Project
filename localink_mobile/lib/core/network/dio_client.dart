import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'dio_auth_policy.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;

  static String get backendHost => AppConfig.backendHost;
  static bool get useHttps => AppConfig.useHttps;

  /// Called only when refresh fails or session is intentionally ended.
  static VoidCallback? onUnauthorized;
  static VoidCallback? onRateLimited;

  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  /// Resolves a potentially relative URL (e.g. `/uploads/abc.jpg`) to an absolute URL.
  static String? resolveUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    final origin = backendOrigin;
    return value.startsWith('/') ? '$origin$value' : '$origin/$value';
  }

  static String get backendOrigin {
    final scheme = useHttps ? 'https' : 'http';
    final host = backendHost;
    // Host may already include port (127.0.0.1:5138)
    return '$scheme://$host';
  }

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    final baseUrlStr = '$backendOrigin/api/v1/';

    final defaultHeaders = <String, dynamic>{
      'Content-Type': 'application/json',
    };
    // Free ngrok interstitial can break WebView / some HTTP stacks without this.
    if (backendHost.contains('ngrok')) {
      defaultHeaders['ngrok-skip-browser-warning'] = '1';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrlStr,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: defaultHeaders,
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
          final path = e.requestOptions.path;

          if (DioAuthPolicy.shouldAttemptRefresh(
            statusCode: e.response?.statusCode,
            path: path,
          )) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              try {
                final token = await SecureStorageService.getToken();
                final opts = e.requestOptions;
                opts.headers['Authorization'] = 'Bearer $token';
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (retryError) {
                if (retryError is DioException) {
                  return handler.next(retryError);
                }
                return handler.next(e);
              }
            }

            onUnauthorized?.call();
          } else if (e.response?.statusCode == 429) {
            onRateLimited?.call();
          }
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(responseBody: true, requestBody: true),
      );
    }
  }

  /// Single-flight refresh so concurrent 401s share one refresh call.
  static Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: '$backendOrigin/api/v1/',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        'auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] is Map) {
        final payload = data['data'] as Map;
        final newAccess = payload['token']?.toString();
        final newRefresh = payload['refreshToken']?.toString();

        if (newAccess != null && newAccess.isNotEmpty) {
          await SecureStorageService.saveToken(newAccess);
          if (newRefresh != null && newRefresh.isNotEmpty) {
            await SecureStorageService.saveRefreshToken(newRefresh);
          }
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      debugPrint('DioClient: Token refresh failed: $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  Dio get dio => _dio;
}
