import '/auth/app_permissions.dart';
import '/auth/permission_service.dart';
import '/backend/schema/enums/enums.dart';

/// Platform owner — cross-company view and full admin capabilities.
bool isSuperAdminRole(UserRole? role) => role == UserRole.superadmin;

/// Company admin (single-company scope in app; tenant-scoped in rules).
bool isCompanyAdminRole(UserRole? role) => role == UserRole.admin;

bool isDirectorRole(UserRole? role) => role == UserRole.director;

bool isManagerRole(UserRole? role) => role == UserRole.manager;

bool isAccountRole(UserRole? role) => role == UserRole.account;

bool isHrRole(UserRole? role) => role == UserRole.hr;

bool isPayrollRole(UserRole? role) => role == UserRole.payroll;

bool isSeniorFloristRole(UserRole? role) => role == UserRole.senior_florist;

bool isFloristRole(UserRole? role) => role == UserRole.florist;

bool isShopFloristRole(UserRole? role) =>
    isSeniorFloristRole(role) || isFloristRole(role);

bool isDriverRole(UserRole? role) => role == UserRole.driver;

bool isPlatformAdminRole(UserRole? role) =>
    isSuperAdminRole(role) || isCompanyAdminRole(role);

bool isOperationsStaffRole(UserRole? role) {
  if (role == null) {
    return false;
  }
  if (isAccountRole(role) || isHrRole(role) || isPayrollRole(role)) {
    return false;
  }
  return isPlatformAdminRole(role) ||
      isDirectorRole(role) ||
      isManagerRole(role) ||
      isShopFloristRole(role);
}

bool isStaffRole(UserRole? role) => isOperationsStaffRole(role);

bool canManageRolePermissions(UserRole? role) =>
    hasAppPermission(role, AppPermission.manageRolePermissions);

bool canAccessSalesDashboard(UserRole? role) {
  if (isDriverRole(role)) {
    return false;
  }
  return hasAppPermission(role, AppPermission.accessSalesDashboard);
}

bool canCreateStaffAccounts(UserRole? role) =>
    hasAppPermission(role, AppPermission.createStaff);

bool canSelectCompanyForStaffRegistration(UserRole? role) =>
    isSuperAdminRole(role);

bool canViewUserList(UserRole? role) =>
    hasAppPermission(role, AppPermission.viewStaffList);

bool canEditStaffRoles(UserRole? role) =>
    hasAppPermission(role, AppPermission.editStaffRoles);

bool canViewInvoices(UserRole? role) =>
    hasAppPermission(role, AppPermission.viewInvoices);

bool canEditInvoices(UserRole? role) =>
    hasAppPermission(role, AppPermission.editInvoices);

bool canCreateInvoices(UserRole? role) =>
    hasAppPermission(role, AppPermission.createInvoices);

bool canVoidInvoices(UserRole? role) =>
    hasAppPermission(role, AppPermission.voidInvoices);

bool canMarkInvoicesPaid(UserRole? role) =>
    hasAppPermission(role, AppPermission.markInvoicesPaid);

/// Invoice list actions, credit customer create, customer invoice flow.
bool canManageCreditAndInvoices(UserRole? role) =>
    canCreateInvoices(role) ||
    canVoidInvoices(role) ||
    canMarkInvoicesPaid(role) ||
    hasAppPermission(role, AppPermission.createCreditCustomers);

bool canViewCreditAndInvoices(UserRole? role) =>
    canViewInvoices(role) ||
    hasAppPermission(role, AppPermission.viewCustomers);

bool canCreateCreditCustomers(UserRole? role) =>
    hasAppPermission(role, AppPermission.createCreditCustomers);

bool canCreateOrders(UserRole? role) =>
    hasAppPermission(role, AppPermission.createOrders);

bool canUpdateOrderStatus(UserRole? role) =>
    hasAppPermission(role, AppPermission.updateOrderStatus);

bool canEditOrderDetails(UserRole? role) =>
    hasAppPermission(role, AppPermission.editOrderDetails);

bool canExportOrderCsv(UserRole? role) =>
    hasAppPermission(role, AppPermission.exportOrdersCsv);

bool canAssignDriver(UserRole? role) =>
    hasAppPermission(role, AppPermission.assignDriver);

bool canPrintCashInvoice(UserRole? role) =>
    hasAppPermission(role, AppPermission.printCashInvoice);

bool canCreateProducts(UserRole? role) =>
    hasAppPermission(role, AppPermission.manageProducts);

bool canEditCompanyProfile(UserRole? role) =>
    hasAppPermission(role, AppPermission.editCompanyProfile);

bool canViewAuditLog(UserRole? role) =>
    hasAppPermission(role, AppPermission.viewAuditLog);

bool canDeleteOrders(UserRole? role) =>
    hasAppPermission(role, AppPermission.deleteOrders);

bool canViewCustomers(UserRole? role) =>
    hasAppPermission(role, AppPermission.viewCustomers);

bool canEditCustomers(UserRole? role) =>
    hasAppPermission(role, AppPermission.editCustomers);

bool canDeleteCustomers(UserRole? role) =>
    hasAppPermission(role, AppPermission.deleteCustomers);

bool canViewDeletedOrders(UserRole? role) =>
    hasAppPermission(role, AppPermission.viewDeletedOrders);

bool canRestoreDeletedOrders(UserRole? role) =>
    hasAppPermission(role, AppPermission.restoreDeletedOrders);

bool canPermanentlyDeleteDeletedOrders(UserRole? role) =>
    hasAppPermission(role, AppPermission.permanentlyDeleteDeletedOrders);

bool canEditProducts(UserRole? role) =>
    hasAppPermission(role, AppPermission.manageProducts);

List<UserRole> baseStaffRegistrationRoleOptions(UserRole? creatorRole) {
  if (isSuperAdminRole(creatorRole)) {
    return List<UserRole>.from(assignableStaffRoles);
  }
  if (isCompanyAdminRole(creatorRole)) {
    return List<UserRole>.from(assignableStaffRoles);
  }
  if (isDirectorRole(creatorRole)) {
    return List<UserRole>.from(assignableStaffRoles);
  }
  return const [];
}

List<UserRole> staffRegistrationRoleOptions(
  UserRole? creatorRole, {
  List<UserRole> tenantRoles = const [],
}) {
  var base = baseStaffRegistrationRoleOptions(creatorRole);
  if (isCompanyAdminRole(creatorRole)) {
    base = base.where((role) => role != UserRole.director).toList();
  }
  if (tenantRoles.isEmpty) {
    return base;
  }
  return base.where(tenantRoles.contains).toList(growable: false);
}

List<UserRole> roleEditOptionsForViewer({
  required UserRole? viewerRole,
  UserRole? targetCurrentRole,
  List<UserRole> tenantRoles = const [],
}) {
  List<UserRole> options;
  if (isSuperAdminRole(viewerRole)) {
    options = <UserRole>[
      UserRole.superadmin,
      ...staffRegistrationRoleOptions(viewerRole, tenantRoles: tenantRoles),
    ];
  } else if (isCompanyAdminRole(viewerRole)) {
    options = staffRegistrationRoleOptions(
      viewerRole,
      tenantRoles: tenantRoles,
    )
        .where((role) => role != UserRole.director)
        .toList(growable: false);
  } else if (isDirectorRole(viewerRole)) {
    options = staffRegistrationRoleOptions(
      viewerRole,
      tenantRoles: tenantRoles,
    ).toList();
  } else if (isManagerRole(viewerRole)) {
    const managerRoles = [
      UserRole.florist,
      UserRole.senior_florist,
      UserRole.driver,
      UserRole.hr,
      UserRole.payroll,
      UserRole.account,
    ];
    options = tenantRoles.isEmpty
        ? managerRoles
        : managerRoles.where(tenantRoles.contains).toList();
  } else {
    options = const [];
  }

  if (targetCurrentRole != null && !options.contains(targetCurrentRole)) {
    return [...options, targetCurrentRole];
  }
  return options;
}

bool isRoleAllowedForStaffRegistration({
  required UserRole role,
  required UserRole? creatorRole,
  List<UserRole> tenantRoles = const [],
}) {
  if (!canCreateStaffAccounts(creatorRole)) {
    return false;
  }
  if (role == UserRole.superadmin) {
    return false;
  }
  return staffRegistrationRoleOptions(
    creatorRole,
    tenantRoles: tenantRoles,
  ).contains(role);
}

bool isRoleAllowedForStaffEdit({
  required UserRole role,
  required UserRole? editorRole,
  UserRole? targetCurrentRole,
  List<UserRole> tenantRoles = const [],
}) {
  if (!canEditStaffRoles(editorRole)) {
    return false;
  }
  if (role == UserRole.superadmin) {
    return isSuperAdminRole(editorRole);
  }
  final options = roleEditOptionsForViewer(
    viewerRole: editorRole,
    targetCurrentRole: targetCurrentRole,
    tenantRoles: tenantRoles,
  );
  return options.contains(role);
}
