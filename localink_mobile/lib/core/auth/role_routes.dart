/// Central role → home route mapping for GoRouter, splash, and login.
class RoleRoutes {
  RoleRoutes._();

  static const continueAs = '/continue-as';

  static String normalize(String? userType) =>
      (userType ?? '').toLowerCase().trim();

  /// Home after an experience has been chosen (or for admin).
  /// - admin → admin dashboard
  /// - businessowner → owner dashboard
  /// - client / user / anything else → consumer home
  static String homeForRole(String? userType) {
    final role = normalize(userType);
    if (role == 'admin') return '/admin-dashboard';
    if (role == 'businessowner') return '/business-dashboard';
    return '/home';
  }

  /// Post-auth destination: Continue As unless an experience (or admin) is resolved.
  static String resolvePostAuthRoute({
    required String? accountType,
    String? activeExperience,
  }) {
    final account = normalize(accountType);
    if (account == 'admin') return '/admin-dashboard';

    final experience = normalize(activeExperience);
    if (experience == 'businessowner') return '/business-dashboard';
    if (experience == 'user' || experience == 'client') return '/home';

    return continueAs;
  }

  /// Maps backend select-experience destination keys to app routes.
  static String routeForDestination(String? destination) {
    switch (normalize(destination)) {
      case 'businessowner':
        return '/business-dashboard';
      case 'register-business':
        return '/register-business';
      case 'admin':
        return '/admin-dashboard';
      case 'user':
      case 'client':
      default:
        return '/home';
    }
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
