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

  group('RoleRoutes access helpers', () {
    test('isAdmin / isBusinessOwner', () {
      expect(RoleRoutes.isAdmin('admin'), isTrue);
      expect(RoleRoutes.isAdmin('client'), isFalse);
      expect(RoleRoutes.isBusinessOwner('businessowner'), isTrue);
      expect(RoleRoutes.isBusinessOwner('client'), isFalse);
    });

    test('canAccessOwnerRoutes excludes plain client', () {
      expect(RoleRoutes.canAccessOwnerRoutes('businessowner'), isTrue);
      expect(RoleRoutes.canAccessOwnerRoutes('admin'), isTrue);
      expect(RoleRoutes.canAccessOwnerRoutes('client'), isFalse);
    });
  });
}
