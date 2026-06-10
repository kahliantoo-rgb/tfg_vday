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

/// Admin UI: register staff, edit orders, company settings entry.
bool isPlatformAdminRole(UserRole? role) =>
    isSuperAdminRole(role) || isCompanyAdminRole(role);

/// Dashboard / order floor staff.
bool isOperationsStaffRole(UserRole? role) {
  if (isAccountRole(role) || isHrRole(role) || isPayrollRole(role)) {
    return false;
  }
  return isPlatformAdminRole(role) ||
      isDirectorRole(role) ||
      isManagerRole(role) ||
      isShopFloristRole(role);
}

/// Legacy alias — operational staff excluding drivers.
bool isStaffRole(UserRole? role) => isOperationsStaffRole(role);

bool canAccessSalesDashboard(UserRole? role) {
  if (isDriverRole(role)) {
    return false;
  }
  return isOperationsStaffRole(role) ||
      isAccountRole(role) ||
      isHrRole(role) ||
      isPayrollRole(role);
}

bool canCreateStaffAccounts(UserRole? role) => isPlatformAdminRole(role);

bool canSelectCompanyForStaffRegistration(UserRole? role) =>
    isSuperAdminRole(role);

bool canViewUserList(UserRole? role) =>
    isPlatformAdminRole(role) ||
    isManagerRole(role) ||
    isDirectorRole(role);

bool canEditStaffRoles(UserRole? role) =>
    isSuperAdminRole(role) ||
    isCompanyAdminRole(role) ||
    isManagerRole(role);

/// Credit customer, invoice generation, invoice payment recording.
/// Super Admin, Admin, Manager, and Account.
bool canManageCreditAndInvoices(UserRole? role) =>
    isPlatformAdminRole(role) ||
    isManagerRole(role) ||
    isAccountRole(role);

/// Read-only access to credit customers and invoice list.
bool canViewCreditAndInvoices(UserRole? role) =>
    canManageCreditAndInvoices(role) || isShopFloristRole(role);

bool canCreateCreditCustomers(UserRole? role) =>
    canManageCreditAndInvoices(role);

bool canCreateOrders(UserRole? role) => isOperationsStaffRole(role);

bool canUpdateOrderStatus(UserRole? role) => isOperationsStaffRole(role);

bool canEditOrderDetails(UserRole? role) =>
    isPlatformAdminRole(role) || isManagerRole(role) || isDirectorRole(role);

bool canExportOrderCsv(UserRole? role) => isOperationsStaffRole(role);

bool canAssignDriver(UserRole? role) =>
    isPlatformAdminRole(role) || isManagerRole(role);

bool canCreateProducts(UserRole? role) => isOperationsStaffRole(role);

bool canEditCompanyProfile(UserRole? role) => isPlatformAdminRole(role);

bool canViewAuditLog(UserRole? role) =>
    isPlatformAdminRole(role) || isDirectorRole(role);

bool canDeleteOrders(UserRole? role) =>
    isPlatformAdminRole(role) || isManagerRole(role);

bool canViewDeletedOrders(UserRole? role) => isOperationsStaffRole(role);

bool canRestoreDeletedOrders(UserRole? role) => isOperationsStaffRole(role);

bool canPermanentlyDeleteDeletedOrders(UserRole? role) =>
    isPlatformAdminRole(role);

bool canEditProducts(UserRole? role) => isOperationsStaffRole(role);

/// Roles superadmin/admin may assign when creating a staff account.
List<UserRole> staffRegistrationRoleOptions(UserRole? creatorRole) {
  if (isSuperAdminRole(creatorRole)) {
    return const [
      UserRole.admin,
      UserRole.director,
      UserRole.manager,
      UserRole.account,
      UserRole.hr,
      UserRole.payroll,
      UserRole.senior_florist,
      UserRole.florist,
      UserRole.driver,
    ];
  }
  if (isCompanyAdminRole(creatorRole)) {
    return const [
      UserRole.senior_florist,
      UserRole.florist,
      UserRole.driver,
      UserRole.admin,
    ];
  }
  return const [];
}

/// Roles a viewer may assign when editing an existing staff profile.
List<UserRole> roleEditOptionsForViewer({
  required UserRole? viewerRole,
  UserRole? targetCurrentRole,
}) {
  if (isSuperAdminRole(viewerRole)) {
    final options = <UserRole>[
      UserRole.superadmin,
      ...staffRegistrationRoleOptions(viewerRole),
    ];
    if (targetCurrentRole != null && !options.contains(targetCurrentRole)) {
      options.add(targetCurrentRole);
    }
    return options;
  }
  if (isCompanyAdminRole(viewerRole)) {
    final options = staffRegistrationRoleOptions(viewerRole).toList();
    if (targetCurrentRole != null && !options.contains(targetCurrentRole)) {
      options.add(targetCurrentRole);
    }
    return options;
  }
  if (isManagerRole(viewerRole)) {
    final options = const [
      UserRole.florist,
      UserRole.senior_florist,
      UserRole.driver,
      UserRole.hr,
      UserRole.payroll,
      UserRole.account,
    ];
    if (targetCurrentRole != null && !options.contains(targetCurrentRole)) {
      return [...options, targetCurrentRole];
    }
    return options;
  }
  return const [];
}

bool isRoleAllowedForStaffRegistration({
  required UserRole role,
  required UserRole? creatorRole,
}) {
  if (!canCreateStaffAccounts(creatorRole)) {
    return false;
  }
  if (role == UserRole.superadmin) {
    return false;
  }
  return staffRegistrationRoleOptions(creatorRole).contains(role);
}

bool isRoleAllowedForStaffEdit({
  required UserRole role,
  required UserRole? editorRole,
  UserRole? targetCurrentRole,
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
  );
  return options.contains(role);
}
