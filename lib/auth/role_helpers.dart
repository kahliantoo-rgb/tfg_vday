import '/backend/schema/enums/enums.dart';

/// Platform owner — cross-company view and full admin capabilities.
bool isSuperAdminRole(UserRole? role) => role == UserRole.superadmin;

/// Company admin (single-company scope in app; tenant-scoped in rules).
bool isCompanyAdminRole(UserRole? role) => role == UserRole.admin;

bool isSeniorFloristRole(UserRole? role) => role == UserRole.senior_florist;

bool isDriverRole(UserRole? role) => role == UserRole.driver;

/// Admin UI: register staff, edit orders, company settings entry.
bool isPlatformAdminRole(UserRole? role) =>
    isSuperAdminRole(role) || isCompanyAdminRole(role);

/// Dashboard / order floor staff (admin + senior florist).
bool isOperationsStaffRole(UserRole? role) =>
    isPlatformAdminRole(role) || isSeniorFloristRole(role);

/// Legacy alias — operational staff excluding drivers.
bool isStaffRole(UserRole? role) => isOperationsStaffRole(role);

bool canCreateStaffAccounts(UserRole? role) => isPlatformAdminRole(role);

bool canSelectCompanyForStaffRegistration(UserRole? role) =>
    isSuperAdminRole(role);

bool canCreateOrders(UserRole? role) => isOperationsStaffRole(role);

bool canUpdateOrderStatus(UserRole? role) => isOperationsStaffRole(role);

bool canEditOrderDetails(UserRole? role) => isPlatformAdminRole(role);

bool canExportOrderCsv(UserRole? role) => isOperationsStaffRole(role);

bool canAssignDriver(UserRole? role) => isPlatformAdminRole(role);

bool canCreateProducts(UserRole? role) => isOperationsStaffRole(role);

bool canEditCompanyProfile(UserRole? role) => isPlatformAdminRole(role);

bool canViewUserList(UserRole? role) => isPlatformAdminRole(role);

bool canViewAuditLog(UserRole? role) => isPlatformAdminRole(role);

bool canDeleteOrders(UserRole? role) => isPlatformAdminRole(role);

/// Deleted Orders dashboard — admin, superadmin, senior florist (not driver).
bool canViewDeletedOrders(UserRole? role) => isOperationsStaffRole(role);

bool canRestoreDeletedOrders(UserRole? role) => isOperationsStaffRole(role);

/// Permanent purge of archived orders — platform admin only.
bool canPermanentlyDeleteDeletedOrders(UserRole? role) =>
    isPlatformAdminRole(role);

bool canEditProducts(UserRole? role) => isOperationsStaffRole(role);

/// Roles an admin/superadmin may assign when creating a staff account.
List<UserRole> staffRegistrationRoleOptions(UserRole? creatorRole) {
  if (!canCreateStaffAccounts(creatorRole)) {
    return const [];
  }
  return [
    UserRole.senior_florist,
    UserRole.driver,
    UserRole.admin,
  ];
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
  if (role == UserRole.admin) {
    return isPlatformAdminRole(creatorRole);
  }
  return role == UserRole.senior_florist || role == UserRole.driver;
}
