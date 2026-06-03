import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/role_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';

void main() {
  group('admin capabilities', () {
    test('admin can edit orders, export, assign driver, create staff', () {
      expect(canEditOrderDetails(UserRole.admin), isTrue);
      expect(canExportOrderCsv(UserRole.admin), isTrue);
      expect(canAssignDriver(UserRole.admin), isTrue);
      expect(canCreateStaffAccounts(UserRole.admin), isTrue);
      expect(
        isRoleAllowedForStaffRegistration(
          role: UserRole.admin,
          creatorRole: UserRole.admin,
        ),
        isTrue,
      );
    });
  });

  group('senior florist capabilities', () {
    test('senior florist can create order, product, update status only', () {
      expect(canCreateOrders(UserRole.senior_florist), isTrue);
      expect(canCreateProducts(UserRole.senior_florist), isTrue);
      expect(canUpdateOrderStatus(UserRole.senior_florist), isTrue);
      expect(canEditOrderDetails(UserRole.senior_florist), isFalse);
      expect(canExportOrderCsv(UserRole.senior_florist), isFalse);
      expect(canAssignDriver(UserRole.senior_florist), isFalse);
      expect(canCreateStaffAccounts(UserRole.senior_florist), isFalse);
      expect(canEditProducts(UserRole.senior_florist), isFalse);
    });
  });
}
