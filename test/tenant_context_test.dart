import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/role_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';

void main() {
  test('superadmin is the only role with cross-company view policy', () {
    expect(isSuperAdminRole(UserRole.superadmin), isTrue);
    expect(isSuperAdminRole(UserRole.admin), isFalse);
    expect(isSuperAdminRole(UserRole.senior_florist), isFalse);
  });
}
