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
  final String? activeExperience;

  /// True only for newly created accounts that must complete Continue As.
  final bool needsExperienceSelection;

  const AuthAuthenticated(
    this.userType,
    this.userId, {
    this.activeExperience,
    this.needsExperienceSelection = false,
  });

  AuthAuthenticated copyWith({
    String? userType,
    int? userId,
    String? activeExperience,
    bool? needsExperienceSelection,
    bool clearActiveExperience = false,
  }) {
    return AuthAuthenticated(
      userType ?? this.userType,
      userId ?? this.userId,
      activeExperience: clearActiveExperience
          ? null
          : (activeExperience ?? this.activeExperience),
      needsExperienceSelection:
          needsExperienceSelection ?? this.needsExperienceSelection,
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
