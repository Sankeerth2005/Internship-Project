import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;

  // 💡 CONFIGURATION FOR EXTERNAL DEVICE / EMULATOR:
  // - For Android Emulator: Use '10.0.2.2'
  // - For Physical Device (USB Debugging): Run `adb reverse tcp:5138 tcp:5138` on your computer terminal and change this to '127.0.0.1'
  // - For Physical Device (same Wi-Fi): Change this to your computer's local IP (e.g., '192.168.1.15')
  static const String backendHost = '192.168.0.106';
  static VoidCallback? onUnauthorized;
  static VoidCallback? onRateLimited;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    String baseUrlStr = 'https://8c24-49-206-52-240.ngrok-free.app/api/v1/';

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
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
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
