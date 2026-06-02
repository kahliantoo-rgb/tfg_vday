import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/role_route_guard.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';

void main() {
  test('Drivers: allowed route for driver role', () {
    final allowedPath = defaultRoutePathForRole(UserRole.driver);
    expect(isRouteAllowedForRole(allowedPath, UserRole.driver), isTrue);
  });

  test('Drivers: disallowed route for driver role', () {
    expect(isRouteAllowedForRole('/some_unexpected_path', UserRole.driver),
        isFalse);
  });

  test('Non-driver roles: always allowed', () {
    expect(isRouteAllowedForRole('/anything', UserRole.admin), isTrue);
    expect(isRouteAllowedForRole('/anything', null), isTrue);
  });
}

