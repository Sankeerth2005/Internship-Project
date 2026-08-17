import 'package:flutter_test/flutter_test.dart';
import 'package:localink_mobile/core/auth/role_routes.dart';

void main() {
  group('RoleRoutes.homeForRole', () {
    test('admin goes to admin dashboard', () {
      expect(RoleRoutes.homeForRole('admin'), '/admin-dashboard');
      expect(RoleRoutes.homeForRole('Admin'), '/admin-dashboard');
    });

    test('businessowner goes to business dashboard', () {
      expect(RoleRoutes.homeForRole('businessowner'), '/business-dashboard');
      expect(RoleRoutes.homeForRole('BusinessOwner'), '/business-dashboard');
    });

    test('client consumer goes to home (not owner dashboard)', () {
      expect(RoleRoutes.homeForRole('client'), '/home');
      expect(RoleRoutes.homeForRole('user'), '/home');
      expect(RoleRoutes.homeForRole(null), '/home');
      expect(RoleRoutes.homeForRole(''), '/home');
    });
  });

  group('RoleRoutes helpers', () {
    test('isAdmin / isBusinessOwner', () {
      expect(RoleRoutes.isAdmin('admin'), isTrue);
      expect(RoleRoutes.isAdmin('client'), isFalse);
      expect(RoleRoutes.isBusinessOwner('businessowner'), isTrue);
      expect(RoleRoutes.isBusinessOwner('client'), isFalse);
    });

    test('canAccessOwnerRoutes', () {
      expect(RoleRoutes.canAccessOwnerRoutes('businessowner'), isTrue);
      expect(RoleRoutes.canAccessOwnerRoutes('admin'), isTrue);
      expect(RoleRoutes.canAccessOwnerRoutes('client'), isFalse);
      expect(RoleRoutes.canAccessOwnerRoutes('user'), isFalse);
    });
  });

  group('RoleRoutes.resolvePostAuthRoute', () {
    test('admin skips continue-as', () {
      expect(
        RoleRoutes.resolvePostAuthRoute(accountType: 'admin'),
        '/admin-dashboard',
      );
    });

    test('new account needs continue-as', () {
      expect(
        RoleRoutes.resolvePostAuthRoute(
          accountType: 'user',
          needsExperienceSelection: true,
        ),
        RoleRoutes.continueAs,
      );
    });

    test('existing account without experience uses account type dashboard', () {
      expect(
        RoleRoutes.resolvePostAuthRoute(accountType: 'user'),
        '/home',
      );
      expect(
        RoleRoutes.resolvePostAuthRoute(accountType: 'businessowner'),
        '/business-dashboard',
      );
    });

    test('interactive login with needsExperienceSelection goes to continue-as', () {
      expect(
        RoleRoutes.resolvePostAuthRoute(
          accountType: 'user',
          needsExperienceSelection: true,
        ),
        RoleRoutes.continueAs,
      );
      expect(
        RoleRoutes.resolvePostAuthRoute(
          accountType: 'businessowner',
          needsExperienceSelection: true,
        ),
        RoleRoutes.continueAs,
      );
    });

    test('selected user experience goes to home', () {
      expect(
        RoleRoutes.resolvePostAuthRoute(
          accountType: 'businessowner',
          activeExperience: 'user',
        ),
        '/home',
      );
    });

    test('selected owner experience goes to owner dashboard', () {
      expect(
        RoleRoutes.resolvePostAuthRoute(
          accountType: 'businessowner',
          activeExperience: 'businessowner',
        ),
        '/business-dashboard',
      );
    });
  });

  group('RoleRoutes.routeForDestination', () {
    test('maps backend destination keys', () {
      expect(RoleRoutes.routeForDestination('user'), '/home');
      expect(RoleRoutes.routeForDestination('businessowner'), '/business-dashboard');
      expect(RoleRoutes.routeForDestination('register-business'), '/register-business');
      expect(RoleRoutes.routeForDestination('admin'), '/admin-dashboard');
    });
  });
}
