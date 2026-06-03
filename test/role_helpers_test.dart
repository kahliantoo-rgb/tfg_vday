import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/role_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';

void main() {
  test('only superadmin has cross-company platform access helpers', () {
    expect(isSuperAdminRole(UserRole.superadmin), isTrue);
    expect(isSuperAdminRole(UserRole.admin), isFalse);
    expect(isSuperAdminRole(UserRole.senior_florist), isFalse);
    expect(isSuperAdminRole(UserRole.driver), isFalse);
  });

  test('platform admin includes superadmin and admin', () {
    expect(isPlatformAdminRole(UserRole.superadmin), isTrue);
    expect(isPlatformAdminRole(UserRole.admin), isTrue);
    expect(isPlatformAdminRole(UserRole.senior_florist), isFalse);
  });

  test('staff roles include superadmin, admin, senior_florist', () {
    expect(isStaffRole(UserRole.superadmin), isTrue);
    expect(isStaffRole(UserRole.admin), isTrue);
    expect(isStaffRole(UserRole.senior_florist), isTrue);
    expect(isStaffRole(UserRole.driver), isFalse);
  });
}
