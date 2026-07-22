import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/signalr_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/network/app_error_formatter.dart';
import '../data/models/login_request.dart';
import '../data/models/register_request.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_state.dart';
import 'user_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(dio: DioClient().dio);
});

class SplashShownNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setShown(bool value) {
    state = value;
  }
}

final splashShownProvider = NotifierProvider<SplashShownNotifier, bool>(
  SplashShownNotifier.new,
);

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
      state = AuthError(AppErrorFormatter.format(e));
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
      final errorMsg = AppErrorFormatter.format(e);
      state = AuthError(errorMsg);
      return null;
    }
  }


  Future<void> logout() async {
    final currentUserId = (state is AuthAuthenticated) ? (state as AuthAuthenticated).userId : null;
    await SignalRService().disconnect(currentUserId);
    await SecureStorageService.clearAll();
    ref.read(userRepositoryProvider).clearCache();
    ref.invalidate(userProfileProvider);
    state = const AuthUnauthenticated();
  }
}
