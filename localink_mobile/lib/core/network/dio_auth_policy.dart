/// Pure helpers for Dio auth/refresh decisions (unit-testable).
class DioAuthPolicy {
  DioAuthPolicy._();

  /// Paths that must not trigger token refresh on 401.
  static bool isAuthBootstrapPath(String path) {
    final p = path.toLowerCase();
    return p.contains('auth/sessions') ||
        p.contains('auth/refresh') ||
        p.contains('auth/logout') ||
        p.contains('auth/register') ||
        p.contains('auth/google');
  }

  /// Whether a 401 should attempt refresh + retry.
  static bool shouldAttemptRefresh({
    required int? statusCode,
    required String path,
  }) {
    return statusCode == 401 && !isAuthBootstrapPath(path);
  }
}
