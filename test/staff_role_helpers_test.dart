import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/role_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/staff_role_helpers.dart';

void main() {
  group('normalizeStaffRoleList', () {
    test('deduplicates and excludes superadmin', () {
      final roles = normalizeStaffRoleList([
        UserRole.admin,
        UserRole.admin,
        UserRole.superadmin,
        UserRole.account,
      ]);

      expect(roles, [UserRole.account, UserRole.admin]);
    });
  });

  group('staffRegistrationRoleOptions', () {
    test('filters admin options by tenant role catalog', () {
      final options = staffRegistrationRoleOptions(
        UserRole.admin,
        tenantRoles: const [
          UserRole.admin,
          UserRole.driver,
          UserRole.account,
        ],
      );

      expect(options, containsAll([
        UserRole.admin,
        UserRole.driver,
        UserRole.account,
      ]));
      expect(options, isNot(contains(UserRole.hr)));
    });
  });
}
