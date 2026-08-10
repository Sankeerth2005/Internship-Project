import 'package:dio/dio.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/auth_response.dart';
import '../models/authorized_experiences.dart';

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

  Future<AuthResponse> googleSignIn(String idToken) async {
    try {
      final response = await dio.post('auth/google', data: {'idToken': idToken});
      if (response.data['success'] == true) {
        return AuthResponse.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Google sign-in failed');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    try {
      final response = await dio.post(
        'auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      if (response.data['success'] == true) {
        return AuthResponse.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Session refresh failed');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<AuthorizedExperiencesDto> getAuthorizedExperiences() async {
    try {
      final response = await dio.get('auth/experiences');
      if (response.data['success'] == true) {
        return AuthorizedExperiencesDto.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw Exception(response.data['message'] ?? 'Failed to load experiences');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<SelectExperienceResultDto> selectExperience(String experience) async {
    try {
      final response = await dio.post(
        'auth/select-experience',
        data: {'experience': experience},
      );
      if (response.data['success'] == true) {
        return SelectExperienceResultDto.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw Exception(response.data['message'] ?? 'Experience selection failed');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> logout(String? refreshToken) async {
    if (refreshToken == null || refreshToken.isEmpty) return;
    try {
      await dio.post('auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {
      // Local logout must succeed even if network revoke fails
    }
  }

  String _handleDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message']?.toString();
      final err = data['error']?.toString();
      final errors = data['errors'];

      if (errors != null && errors is List && errors.isNotEmpty) {
        final errorMessages = errors.map((e) {
          if (e is Map) {
            final fieldErrors = e['errors'];
            if (fieldErrors is List && fieldErrors.isNotEmpty) {
              return fieldErrors.join(', ');
            }
          }
          return '';
        }).where((s) => s.isNotEmpty).join('; ');
        if (errorMessages.isNotEmpty) {
          return errorMessages;
        }
      }

      if (msg != null && msg.isNotEmpty && msg != "Something went wrong") {
        return msg;
      }
      if (err != null && err.isNotEmpty) return err;
      if (msg != null && msg.isNotEmpty) return msg;
    } else if (data is String &&
        data.isNotEmpty &&
        !data.contains('<!DOCTYPE')) {
      return data;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
