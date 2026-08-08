/// Central role → home route mapping for GoRouter, splash, and login.
class RoleRoutes {
  RoleRoutes._();

  static String normalize(String? userType) =>
      (userType ?? '').toLowerCase().trim();

  /// Home after auth for the given backend account type.
  /// - admin → admin dashboard
  /// - businessowner → owner dashboard
  /// - client / user / anything else → consumer home
  static String homeForRole(String? userType) {
    final role = normalize(userType);
    if (role == 'admin') return '/admin-dashboard';
    if (role == 'businessowner') return '/business-dashboard';
    return '/home';
  }

  static bool isAdmin(String? userType) => normalize(userType) == 'admin';

  static bool isBusinessOwner(String? userType) =>
      normalize(userType) == 'businessowner';

  /// Owner-only surfaces (admin may also access where product allows).
  static bool canAccessOwnerRoutes(String? userType) {
    final role = normalize(userType);
    return role == 'businessowner' || role == 'admin';
  }
}
