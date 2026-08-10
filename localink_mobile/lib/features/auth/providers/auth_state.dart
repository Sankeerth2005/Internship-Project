abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String userType;
  final int userId;

  /// Backend-validated experience for this device session: `user` | `businessowner`.
  /// Null means Continue As has not been completed yet for this login.
  final String? activeExperience;

  const AuthAuthenticated(
    this.userType,
    this.userId, {
    this.activeExperience,
  });

  AuthAuthenticated copyWith({
    String? userType,
    int? userId,
    String? activeExperience,
    bool clearActiveExperience = false,
  }) {
    return AuthAuthenticated(
      userType ?? this.userType,
      userId ?? this.userId,
      activeExperience: clearActiveExperience
          ? null
          : (activeExperience ?? this.activeExperience),
    );
  }
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
