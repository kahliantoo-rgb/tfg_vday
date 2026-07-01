import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/app_permissions.dart';
import 'package:tfg_vday/auth/role_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';

void main() {
  group('account role defaults', () {
    test('can view and edit invoices but not assign driver', () {
      expect(canViewInvoices(UserRole.account), isTrue);
      expect(canEditInvoices(UserRole.account), isTrue);
      expect(canCreateInvoices(UserRole.account), isTrue);
      expect(canMarkInvoicesPaid(UserRole.account), isTrue);
      expect(canVoidInvoices(UserRole.account), isFalse);
      expect(canAssignDriver(UserRole.account), isFalse);
      expect(canPrintCashInvoice(UserRole.account), isTrue);
      expect(canViewCustomers(UserRole.account), isTrue);
      expect(canEditCustomers(UserRole.account), isFalse);
      expect(canCreateOrders(UserRole.account), isFalse);
    });
  });

  group('director role defaults', () {
    test('director can edit staff roles and manage role permissions', () {
      expect(canEditStaffRoles(UserRole.director), isTrue);
      expect(canManageRolePermissions(UserRole.director), isTrue);
      expect(canManageRolePermissions(UserRole.admin), isTrue);
      expect(canManageRolePermissions(UserRole.superadmin), isTrue);
      expect(canManageRolePermissions(UserRole.manager), isFalse);
    });

    test('admin can add staff by default', () {
      expect(canCreateStaffAccounts(UserRole.admin), isTrue);
      expect(canCreateStaffAccounts(UserRole.director), isTrue);
      expect(canCreateStaffAccounts(UserRole.manager), isFalse);
    });
  });

  group('assignable staff roles', () {
    test('includes operational roles for superadmin registration', () {
      expect(
        staffRegistrationRoleOptions(UserRole.superadmin),
        containsAll([
          UserRole.director,
          UserRole.admin,
          UserRole.account,
          UserRole.driver,
          UserRole.florist,
        ]),
      );
    });
  });
}
