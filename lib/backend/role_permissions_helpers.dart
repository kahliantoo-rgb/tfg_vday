import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/app_permissions.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/flutter_flow/flutter_flow_util.dart';

DocumentReference? tenantRolePermissionsDocRef() {
  final ref = TenantContext.instance.writeCompanyRef ??
      TenantContext.instance.activeCompanyRef;
  if (ref == null) {
    return null;
  }
  return FirebaseFirestore.instance
      .collection('role_permissions')
      .doc(canonicalCompanyId(ref.id));
}

/// roleKey -> permissionKey -> enabled
typedef RolePermissionOverrides = Map<String, Map<String, bool>>;

RolePermissionOverrides parseRolePermissionOverrides(
  Map<String, dynamic>? data,
) {
  if (data == null) {
    return {};
  }
  final rawRoles = data['roles'];
  if (rawRoles is! Map) {
    return {};
  }
  final parsed = <String, Map<String, bool>>{};
  rawRoles.forEach((roleKey, value) {
    if (roleKey is! String || value is! Map) {
      return;
    }
    final permissions = <String, bool>{};
    value.forEach((permissionKey, enabled) {
      if (permissionKey is String && enabled is bool) {
        permissions[permissionKey] = enabled;
      }
    });
    if (permissions.isNotEmpty) {
      parsed[roleKey] = permissions;
    }
  });
  return parsed;
}

Future<RolePermissionOverrides> loadTenantRolePermissionOverrides() async {
  final docRef = tenantRolePermissionsDocRef();
  if (docRef == null) {
    return {};
  }
  final snapshot = await docRef.get();
  return parseRolePermissionOverrides(
    snapshot.data() as Map<String, dynamic>?,
  );
}

Stream<RolePermissionOverrides> streamTenantRolePermissionOverrides() {
  final docRef = tenantRolePermissionsDocRef();
  if (docRef == null) {
    return Stream.value({});
  }
  return docRef.snapshots().map(
        (snapshot) => parseRolePermissionOverrides(
          snapshot.data() as Map<String, dynamic>?,
        ),
      );
}

Future<void> saveTenantRolePermissionOverrides(
  RolePermissionOverrides overrides,
) async {
  final docRef = tenantRolePermissionsDocRef();
  final companyRef = TenantContext.instance.writeCompanyRef ??
      TenantContext.instance.activeCompanyRef;
  if (docRef == null || companyRef == null) {
    throw StateError('No company selected for role permission save.');
  }
  await docRef.set(
    {
      'companyRef': companyRef,
      'roles': overrides,
      'updated_time': getCurrentTimestamp,
    },
    SetOptions(merge: true),
  );
}

Map<String, Map<String, bool>> buildRolePermissionPayload({
  required RolePermissionOverrides overrides,
}) {
  final payload = <String, Map<String, bool>>{};
  for (final role in configurableStaffRoles) {
    final roleKey = rolePermissionKey(role);
    final roleOverrides = overrides[roleKey];
    if (roleOverrides == null || roleOverrides.isEmpty) {
      continue;
    }
    payload[roleKey] = Map<String, bool>.from(roleOverrides);
  }
  return payload;
}

bool? resolvePermissionOverride(
  RolePermissionOverrides overrides,
  UserRole role,
  AppPermission permission,
) {
  final roleOverrides = overrides[rolePermissionKey(role)];
  if (roleOverrides == null) {
    return null;
  }
  return roleOverrides[appPermissionKey(permission)];
}

bool effectivePermission({
  required UserRole? role,
  required AppPermission permission,
  RolePermissionOverrides overrides = const {},
}) {
  if (role == null) {
    return false;
  }
  if (role == UserRole.superadmin) {
    return true;
  }
  final override = resolvePermissionOverride(overrides, role, permission);
  if (override != null) {
    return override;
  }
  return defaultPermissionsForRole(role).contains(permission);
}
