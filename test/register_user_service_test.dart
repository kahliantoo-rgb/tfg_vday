import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/register_user_service.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';

void main() {
  group('isRoleAllowedForRegistration', () {
    test('allows senior florist and driver', () {
      expect(
        isRoleAllowedForRegistration(UserRole.senior_florist),
        isTrue,
      );
      expect(isRoleAllowedForRegistration(UserRole.driver), isTrue);
    });

    test('disallows admin', () {
      expect(isRoleAllowedForRegistration(UserRole.admin), isFalse);
    });
  });

  group('userRoleLabel', () {
    test('returns readable labels', () {
      expect(userRoleLabel(UserRole.driver), 'Driver');
      expect(userRoleLabel(UserRole.senior_florist), 'Senior Florist');
    });
  });
}
