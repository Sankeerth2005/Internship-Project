import 'package:flutter_test/flutter_test.dart';
import 'package:localink_mobile/core/auth/role_routes.dart';
import 'package:localink_mobile/core/config/app_config.dart';

void main() {
  test('Smoke — role routing + config defaults are sane', () {
    expect(RoleRoutes.homeForRole('client'), '/home');
    expect(RoleRoutes.homeForRole('businessowner'), '/business-dashboard');
    expect(RoleRoutes.homeForRole('admin'), '/admin-dashboard');
    expect(AppConfig.backendHost, isNotEmpty);
  });
}
