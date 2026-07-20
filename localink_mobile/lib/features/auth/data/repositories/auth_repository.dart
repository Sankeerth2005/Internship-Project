import 'package:dio/dio.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final Dio dio;

  AuthRepository({required this.dio});

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await dio.post('auth/sessions', data: request.toJson());
      if (response.data['success'] == true) {
        return AuthResponse.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<String> register(RegisterRequest request) async {
    try {
      final response = await dio.post('auth/register', data: request.toJson());
      if (response.data['success'] == true) {
        return response.data['message'] ?? 'Registration successful';
      } else {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  String _handleDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message']?.toString();
      final err = data['error']?.toString();
      if (msg != null && msg.isNotEmpty && msg != "Something went wrong") return msg;
      if (err != null && err.isNotEmpty) return err;
      if (msg != null && msg.isNotEmpty) return msg;
    } else if (data is String && data.isNotEmpty && !data.contains('<!DOCTYPE')) {
      return data;
    }
    if (error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
