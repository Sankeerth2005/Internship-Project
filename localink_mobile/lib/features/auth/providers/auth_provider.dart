import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/models/login_request.dart';
import '../data/models/register_request.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_state.dart';
import 'user_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(dio: DioClient().dio);
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    
    // Wire unauthorized response handler to cleanly logout when session/token expires
    DioClient.onUnauthorized = () {
      logout();
    };

    Future.microtask(() => checkAuthStatus());
    return const AuthInitial();
  }

  Future<void> checkAuthStatus() async {
    final token = await SecureStorageService.getToken();
    final userType = await SecureStorageService.getUserType();
    final userId = await SecureStorageService.getUserId();

    if (token != null && userType != null && userId != null) {
      state = AuthAuthenticated(userType, userId);
    } else {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String usernameOrEmail, String password) async {
    state = const AuthLoading();
    try {
      final request = LoginRequest(
        usernameOrEmail: usernameOrEmail,
        password: password,
        captchaToken:
            'string', // Bypass captcha check for local testing
      );

      final response = await _repository.login(request);
      final parsedUserId = int.tryParse(response.user.id) ?? 0;

      await SecureStorageService.saveToken(response.token);
      await SecureStorageService.saveUserType(response.user.userType);
      await SecureStorageService.saveUserId(parsedUserId);

      ref.read(userRepositoryProvider).clearCache();
      ref.invalidate(userProfileProvider);
      state = AuthAuthenticated(response.user.userType, parsedUserId);
    } catch (e) {
      String errorMessage = 'Something went wrong. Please try again.';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'The email or password you entered is incorrect. Please double-check your details and try again';
        } else if (e.response?.statusCode == 429) {
          errorMessage = 'Too many requests. Please wait a moment before trying again.';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timeout. Please check your internet connection and try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Server is unreachable. Please check if you are connected to the internet.';
        } else if (e.response?.data != null && e.response?.data is Map) {
          final data = e.response?.data as Map;
          errorMessage = data['message'] ?? data['title'] ?? e.message ?? errorMessage;
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      state = AuthError(errorMessage);
      // We don't reset to AuthUnauthenticated immediately because the UI needs to react to AuthError
    }
  }

  Future<String?> register(RegisterRequest request) async {
    state = const AuthLoading();
    try {
      final message = await _repository.register(request);
      state =
          const AuthUnauthenticated(); // Go back to unauthenticated to allow login
      return message;
    } catch (e) {
      String errorMessage = 'Registration failed. Please try again.';
      if (e is DioException) {
        if (e.response?.statusCode == 429) {
          errorMessage = 'Too many requests. Please wait a moment before trying again.';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timeout. Please check your internet connection and try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Server is unreachable. Please check if you are connected to the internet.';
        } else if (e.response?.data != null && e.response?.data is Map) {
          final data = e.response?.data as Map;
          errorMessage = data['message'] ?? data['title'] ?? e.message ?? errorMessage;
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      state = AuthError(errorMessage);
      return null;
    }
  }


  Future<void> logout() async {
    await SecureStorageService.clearAll();
    ref.read(userRepositoryProvider).clearCache();
    ref.invalidate(userProfileProvider);
    state = const AuthUnauthenticated();
  }
}
