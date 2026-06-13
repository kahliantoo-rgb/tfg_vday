import '/backend/schema/enums/enums.dart';

/// Granular app permissions — company directors can override per role in Firestore.
enum AppPermission {
  manageRolePermissions,
  viewInvoices,
  editInvoices,
  createInvoices,
  voidInvoices,
  markInvoicesPaid,
  viewCustomers,
  editCustomers,
  createCreditCustomers,
  deleteCustomers,
  viewOrders,
  createOrders,
  editOrderDetails,
  updateOrderStatus,
  assignDriver,
  printCashInvoice,
  manageProducts,
  viewStaffList,
  createStaff,
  editStaffRoles,
  exportOrdersCsv,
  deleteOrders,
  viewDeletedOrders,
  restoreDeletedOrders,
  permanentlyDeleteDeletedOrders,
  editCompanyProfile,
  viewAuditLog,
  accessSalesDashboard,
}

/// Roles shown on the permission matrix (superadmin is platform owner — not configurable).
const configurableStaffRoles = <UserRole>[
  UserRole.director,
  UserRole.admin,
  UserRole.manager,
  UserRole.account,
  UserRole.hr,
  UserRole.payroll,
  UserRole.senior_florist,
  UserRole.florist,
  UserRole.driver,
];

/// Roles that can be assigned when adding staff (same canonical list).
const assignableStaffRoles = configurableStaffRoles;

String appPermissionKey(AppPermission permission) => permission.name;

AppPermission? parseAppPermissionKey(String key) {
  for (final permission in AppPermission.values) {
    if (permission.name == key) {
      return permission;
    }
  }
  return null;
}

String rolePermissionKey(UserRole role) => role.serialize();

UserRole? parseRolePermissionKey(String key) =>
    UserRole.values.deserialize(key);

String appPermissionLabel(AppPermission permission) {
  switch (permission) {
    case AppPermission.manageRolePermissions:
      return 'Manage role permissions';
    case AppPermission.viewInvoices:
      return 'View invoices';
    case AppPermission.editInvoices:
      return 'Edit invoices';
    case AppPermission.createInvoices:
      return 'Create invoices';
    case AppPermission.voidInvoices:
      return 'Void invoices';
    case AppPermission.markInvoicesPaid:
      return 'Mark invoices paid';
    case AppPermission.viewCustomers:
      return 'View customers';
    case AppPermission.editCustomers:
      return 'Edit customers';
    case AppPermission.createCreditCustomers:
      return 'Create credit customers';
    case AppPermission.deleteCustomers:
      return 'Delete customers';
    case AppPermission.viewOrders:
      return 'View orders';
    case AppPermission.createOrders:
      return 'Create orders';
    case AppPermission.editOrderDetails:
      return 'Edit order details';
    case AppPermission.updateOrderStatus:
      return 'Update order status';
    case AppPermission.assignDriver:
      return 'Assign driver';
    case AppPermission.printCashInvoice:
      return 'Print cash invoice (order)';
    case AppPermission.manageProducts:
      return 'Manage products';
    case AppPermission.viewStaffList:
      return 'View staff list';
    case AppPermission.createStaff:
      return 'Add staff';
    case AppPermission.editStaffRoles:
      return 'Edit staff roles';
    case AppPermission.exportOrdersCsv:
      return 'Export orders CSV';
    case AppPermission.deleteOrders:
      return 'Delete orders';
    case AppPermission.viewDeletedOrders:
      return 'View deleted orders';
    case AppPermission.restoreDeletedOrders:
      return 'Restore deleted orders';
    case AppPermission.permanentlyDeleteDeletedOrders:
      return 'Permanently delete archived orders';
    case AppPermission.editCompanyProfile:
      return 'Edit company profile';
    case AppPermission.viewAuditLog:
      return 'View audit log';
    case AppPermission.accessSalesDashboard:
      return 'Access sales dashboard';
  }
}

String userRoleLabel(UserRole role) {
  switch (role) {
    case UserRole.superadmin:
      return 'Super Admin (owner)';
    case UserRole.admin:
      return 'Admin';
    case UserRole.director:
      return 'Director';
    case UserRole.manager:
      return 'Manager';
    case UserRole.account:
      return 'Account';
    case UserRole.hr:
      return 'HR';
    case UserRole.payroll:
      return 'Payroll';
    case UserRole.senior_florist:
      return 'Senior Florist';
    case UserRole.florist:
      return 'Florist';
    case UserRole.driver:
      return 'Driver';
  }
}

Set<AppPermission> _allPermissions() =>
    AppPermission.values.toSet();

Set<AppPermission> _operationsFloorPermissions() => {
      AppPermission.accessSalesDashboard,
      AppPermission.viewOrders,
      AppPermission.createOrders,
      AppPermission.updateOrderStatus,
      AppPermission.exportOrdersCsv,
      AppPermission.manageProducts,
      AppPermission.viewDeletedOrders,
      AppPermission.restoreDeletedOrders,
      AppPermission.viewCustomers,
      AppPermission.editCustomers,
      AppPermission.viewInvoices,
    };

Set<AppPermission> defaultPermissionsForRole(UserRole role) {
  switch (role) {
    case UserRole.superadmin:
      return _allPermissions();
    case UserRole.director:
      return {
        ..._operationsFloorPermissions(),
        AppPermission.manageRolePermissions,
        AppPermission.viewStaffList,
        AppPermission.viewAuditLog,
        AppPermission.editOrderDetails,
        AppPermission.assignDriver,
        AppPermission.deleteOrders,
        AppPermission.createStaff,
        AppPermission.editInvoices,
        AppPermission.createInvoices,
        AppPermission.voidInvoices,
        AppPermission.markInvoicesPaid,
        AppPermission.createCreditCustomers,
        AppPermission.printCashInvoice,
      };
    case UserRole.admin:
      return {
        ..._operationsFloorPermissions(),
        AppPermission.manageRolePermissions,
        AppPermission.viewStaffList,
        AppPermission.createStaff,
        AppPermission.editStaffRoles,
        AppPermission.editOrderDetails,
        AppPermission.assignDriver,
        AppPermission.deleteOrders,
        AppPermission.permanentlyDeleteDeletedOrders,
        AppPermission.editCompanyProfile,
        AppPermission.viewAuditLog,
        AppPermission.editInvoices,
        AppPermission.createInvoices,
        AppPermission.voidInvoices,
        AppPermission.markInvoicesPaid,
        AppPermission.createCreditCustomers,
        AppPermission.deleteCustomers,
        AppPermission.printCashInvoice,
      };
    case UserRole.manager:
      return {
        ..._operationsFloorPermissions(),
        AppPermission.viewStaffList,
        AppPermission.editStaffRoles,
        AppPermission.editOrderDetails,
        AppPermission.assignDriver,
        AppPermission.deleteOrders,
        AppPermission.editInvoices,
        AppPermission.createInvoices,
        AppPermission.voidInvoices,
        AppPermission.markInvoicesPaid,
        AppPermission.createCreditCustomers,
        AppPermission.printCashInvoice,
      };
    case UserRole.account:
      return {
        AppPermission.accessSalesDashboard,
        AppPermission.viewInvoices,
        AppPermission.editInvoices,
        AppPermission.createInvoices,
        AppPermission.markInvoicesPaid,
        AppPermission.viewCustomers,
        AppPermission.viewOrders,
        AppPermission.printCashInvoice,
      };
    case UserRole.hr:
    case UserRole.payroll:
      return {
        AppPermission.accessSalesDashboard,
      };
    case UserRole.senior_florist:
    case UserRole.florist:
      return _operationsFloorPermissions();
    case UserRole.driver:
      return {
        AppPermission.viewOrders,
        AppPermission.updateOrderStatus,
      };
  }
}

/// Permissions directors can toggle per role in the matrix UI.
List<AppPermission> editablePermissionKeys() => const [
      AppPermission.viewInvoices,
      AppPermission.editInvoices,
      AppPermission.createInvoices,
      AppPermission.voidInvoices,
      AppPermission.markInvoicesPaid,
      AppPermission.viewCustomers,
      AppPermission.editCustomers,
      AppPermission.createCreditCustomers,
      AppPermission.deleteCustomers,
      AppPermission.viewOrders,
      AppPermission.createOrders,
      AppPermission.editOrderDetails,
      AppPermission.updateOrderStatus,
      AppPermission.assignDriver,
      AppPermission.printCashInvoice,
      AppPermission.manageProducts,
      AppPermission.viewStaffList,
      AppPermission.createStaff,
      AppPermission.editStaffRoles,
      AppPermission.exportOrdersCsv,
      AppPermission.deleteOrders,
      AppPermission.viewDeletedOrders,
      AppPermission.restoreDeletedOrders,
      AppPermission.permanentlyDeleteDeletedOrders,
      AppPermission.editCompanyProfile,
      AppPermission.viewAuditLog,
    ];
