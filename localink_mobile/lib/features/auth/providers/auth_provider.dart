import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/signalr_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/network/app_error_formatter.dart';
import '../data/models/login_request.dart';
import '../data/models/register_request.dart';
import '../data/models/auth_response.dart';
import '../data/models/authorized_experiences.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_state.dart';
import 'user_provider.dart';
import '../../business/providers/business_provider.dart';

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
  bool _loggingOut = false;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);

    // Only fires after refresh token fails — not on every access-token expiry
    DioClient.onUnauthorized = () {
      logout(revokeServerSession: false);
    };

    Future.microtask(() => checkAuthStatus());
    return const AuthInitial();
  }

  Future<void> checkAuthStatus() async {
    final token = await SecureStorageService.getToken();
    final refreshToken = await SecureStorageService.getRefreshToken();
    final userType = await SecureStorageService.getUserType();
    final userId = await SecureStorageService.getUserId();
    final activeExperience = await SecureStorageService.getActiveExperience();

    if (userType == null || userId == null) {
      state = const AuthUnauthenticated();
      return;
    }

    // Prefer validating/refreshing the session on cold start so revoked
    // tokens don't look authenticated until the first API 401.
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final refreshed = await _repository.refresh(refreshToken);
        await _persistSession(
          refreshed,
          clearActiveExperience: false,
          preserveActiveExperience: activeExperience,
        );
        return;
      } catch (_) {
        await SecureStorageService.clearAuth();
        state = const AuthUnauthenticated();
        return;
      }
    }

    if (token != null && token.isNotEmpty) {
      // Legacy session without refresh token — keep until first 401, then logout.
      state = AuthAuthenticated(
        userType,
        userId,
        activeExperience: activeExperience,
      );
      return;
    }

    state = const AuthUnauthenticated();
  }

  Future<void> _persistSession(
    AuthResponse response, {
    required bool clearActiveExperience,
    String? preserveActiveExperience,
  }) async {
    final parsedUserId = int.tryParse(response.user.id) ?? 0;

    await SecureStorageService.saveToken(response.token);
    if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
      await SecureStorageService.saveRefreshToken(response.refreshToken!);
    }
    await SecureStorageService.saveUserType(response.user.userType);
    await SecureStorageService.saveUserId(parsedUserId);

    String? experience;
    if (clearActiveExperience) {
      await SecureStorageService.clearActiveExperience();
      experience = null;
    } else {
      experience = preserveActiveExperience ??
          await SecureStorageService.getActiveExperience();
    }

    ref.read(userRepositoryProvider).clearCache();
    ref.invalidate(userProfileProvider);
    ref.invalidate(myBusinessesProvider);
    state = AuthAuthenticated(
      response.user.userType,
      parsedUserId,
      activeExperience: experience,
    );
  }

  Future<void> login(
    String usernameOrEmail,
    String password,
  ) async {
    state = const AuthLoading();
    try {
      final request = LoginRequest(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );

      final response = await _repository.login(request);
      // Fresh login must show Continue As (do not reuse prior experience).
      await _persistSession(response, clearActiveExperience: true);
    } catch (e) {
      state = AuthError(AppErrorFormatter.format(e));
    }
  }

  Future<String?> register(RegisterRequest request) async {
    state = const AuthLoading();
    try {
      final message = await _repository.register(request);
      state = const AuthUnauthenticated();
      return message;
    } catch (e) {
      final errorMsg = AppErrorFormatter.format(e);
      state = AuthError(errorMsg);
      return null;
    }
  }

  Future<void> googleSignIn(String idToken) async {
    state = const AuthLoading();
    try {
      final response = await _repository.googleSignIn(idToken);
      await _persistSession(response, clearActiveExperience: true);
    } catch (e) {
      state = AuthError(AppErrorFormatter.format(e));
    }
  }

  Future<AuthorizedExperiencesDto> loadAuthorizedExperiences() {
    return _repository.getAuthorizedExperiences();
  }

  /// Validates experience with the backend, then persists it for session restore.
  Future<SelectExperienceResultDto> selectExperience(String experience) async {
    final result = await _repository.selectExperience(experience);
    final current = state;
    if (current is! AuthAuthenticated) {
      throw Exception('Not authenticated');
    }

    if (result.allowed) {
      await SecureStorageService.saveActiveExperience(result.experience);
      state = current.copyWith(activeExperience: result.experience);
    }

    return result;
  }

  /// After first business registration, refresh JWT/account type and enter Owner.
  Future<void> syncSessionAfterOwnerOnboarding() async {
    final refreshToken = await SecureStorageService.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final refreshed = await _repository.refresh(refreshToken);
        await SecureStorageService.saveActiveExperience('businessowner');
        await _persistSession(
          refreshed,
          clearActiveExperience: false,
          preserveActiveExperience: 'businessowner',
        );
        return;
      } catch (_) {
        // Fall through to local promotion if refresh fails.
      }
    }

    final current = state;
    if (current is AuthAuthenticated) {
      await SecureStorageService.saveUserType('businessowner');
      await SecureStorageService.saveActiveExperience('businessowner');
      state = current.copyWith(
        userType: 'businessowner',
        activeExperience: 'businessowner',
      );
    }
  }

  Future<void> logout({bool revokeServerSession = true}) async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      final currentUserId =
          (state is AuthAuthenticated) ? (state as AuthAuthenticated).userId : null;

      if (revokeServerSession) {
        final refreshToken = await SecureStorageService.getRefreshToken();
        await _repository.logout(refreshToken);
      }

      await SignalRService().disconnect(currentUserId);
      await SecureStorageService.clearAuth();
      ref.read(userRepositoryProvider).clearCache();
      ref.invalidate(userProfileProvider);
      ref.invalidate(myBusinessesProvider);
      state = const AuthUnauthenticated();
    } finally {
      _loggingOut = false;
    }
  }
}
