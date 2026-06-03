import '/backend/schema/enums/enums.dart';

/// Platform owner — cross-company view and full admin capabilities.
bool isSuperAdminRole(UserRole? role) => role == UserRole.superadmin;

/// Company admin (single-company scope in app; tenant-scoped in rules).
bool isCompanyAdminRole(UserRole? role) => role == UserRole.admin;

/// Admin UI: register staff, edit orders, company settings entry.
bool isPlatformAdminRole(UserRole? role) =>
    isSuperAdminRole(role) || isCompanyAdminRole(role);

/// Staff who operate orders (not drivers).
bool isStaffRole(UserRole? role) =>
    role == UserRole.superadmin ||
    role == UserRole.admin ||
    role == UserRole.senior_florist;
