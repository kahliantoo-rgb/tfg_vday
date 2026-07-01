import '/auth/app_permissions.dart';
import '/backend/role_permissions_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/users_record.dart';

/// Per-user permission overrides: permissionKey -> enabled.
typedef UserPermissionOverrides = Map<String, bool>;

UserPermissionOverrides parseUserPermissionOverrides(UsersRecord? user) {
  if (user == null) {
    return {};
  }
  return Map<String, bool>.from(user.permissionOverrides);
}

bool? resolveUserPermissionOverride(
  UserPermissionOverrides overrides,
  AppPermission permission,
) {
  return overrides[appPermissionKey(permission)];
}

bool effectivePermissionForUser({
  required UserRole? role,
  required AppPermission permission,
  RolePermissionOverrides roleOverrides = const {},
  UserPermissionOverrides userOverrides = const {},
}) {
  if (role == null) {
    return false;
  }
  if (role == UserRole.superadmin) {
    return true;
  }

  final userOverride = resolveUserPermissionOverride(userOverrides, permission);
  if (userOverride != null) {
    return userOverride;
  }

  return effectivePermission(
    role: role,
    permission: permission,
    overrides: roleOverrides,
  );
}

bool userPermissionDiffersFromDefault({
  required UserRole role,
  required AppPermission permission,
  required UserPermissionOverrides overrides,
  RolePermissionOverrides roleOverrides = const {},
}) {
  final override = resolveUserPermissionOverride(overrides, permission);
  if (override == null) {
    return false;
  }
  final baseline = effectivePermission(
    role: role,
    permission: permission,
    overrides: roleOverrides,
  );
  return override != baseline;
}

UserPermissionOverrides sanitizeUserPermissionOverrides({
  required UserRole role,
  required UserPermissionOverrides draft,
  RolePermissionOverrides roleOverrides = const {},
}) {
  final sanitized = <String, bool>{};
  for (final permission in editablePermissionKeys()) {
    final key = appPermissionKey(permission);
    final value = draft[key];
    if (value == null) {
      continue;
    }
    final baseline = effectivePermission(
      role: role,
      permission: permission,
      overrides: roleOverrides,
    );
    if (value != baseline) {
      sanitized[key] = value;
    }
  }
  return sanitized;
}
