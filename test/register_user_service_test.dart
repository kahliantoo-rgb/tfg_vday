import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/register_user_service.dart';
import 'package:tfg_vday/auth/role_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';

void main() {
  group('isRoleAllowedForStaffRegistration', () {
    test('admin creator allows admin, senior florist, driver', () {
      expect(
        isRoleAllowedForStaffRegistration(
          role: UserRole.senior_florist,
          creatorRole: UserRole.admin,
        ),
        isTrue,
      );
      expect(
        isRoleAllowedForStaffRegistration(
          role: UserRole.driver,
          creatorRole: UserRole.admin,
        ),
        isTrue,
      );
      expect(
        isRoleAllowedForStaffRegistration(
          role: UserRole.admin,
          creatorRole: UserRole.admin,
        ),
        isTrue,
      );
      expect(
        isRoleAllowedForStaffRegistration(
          role: UserRole.superadmin,
          creatorRole: UserRole.admin,
        ),
        isFalse,
      );
    });

    test('senior florist cannot create staff', () {
      expect(
        isRoleAllowedForStaffRegistration(
          role: UserRole.driver,
          creatorRole: UserRole.senior_florist,
        ),
        isFalse,
      );
    });
  });

  group('userRoleLabel', () {
    test('returns readable labels', () {
      expect(userRoleLabel(UserRole.superadmin), 'Super Admin');
      expect(userRoleLabel(UserRole.driver), 'Driver');
      expect(userRoleLabel(UserRole.senior_florist), 'Senior Florist');
    });
  });

  group('staff registration access', () {
    test('canCreateStaffAccounts allows admin and superadmin', () {
      expect(canCreateStaffAccounts(UserRole.admin), isTrue);
      expect(canCreateStaffAccounts(UserRole.superadmin), isTrue);
      expect(canCreateStaffAccounts(UserRole.senior_florist), isFalse);
      expect(canCreateStaffAccounts(UserRole.driver), isFalse);
    });

    test('canSelectCompanyForStaffRegistration is superadmin only', () {
      expect(canSelectCompanyForStaffRegistration(UserRole.superadmin), isTrue);
      expect(canSelectCompanyForStaffRegistration(UserRole.admin), isFalse);
      expect(canSelectCompanyForStaffRegistration(UserRole.senior_florist), isFalse);
    });
  });
}
