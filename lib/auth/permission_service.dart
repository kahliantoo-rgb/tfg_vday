import 'dart:async';

import 'package:flutter/foundation.dart';

import '/auth/app_permissions.dart';
import '/backend/role_permissions_helpers.dart';
import '/backend/schema/enums/enums.dart';

/// Company-scoped permission overrides loaded from Firestore.
class PermissionService extends ChangeNotifier {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  RolePermissionOverrides _overrides = {};
  StreamSubscription<RolePermissionOverrides>? _subscription;

  RolePermissionOverrides get overrides => _overrides;

  void setOverrides(RolePermissionOverrides overrides) {
    _overrides = overrides;
    notifyListeners();
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _overrides = {};
    notifyListeners();
  }

  bool hasPermission(UserRole? role, AppPermission permission) =>
      effectivePermission(
        role: role,
        permission: permission,
        overrides: _overrides,
      );

  bool permissionForRole(UserRole role, AppPermission permission) {
    final override = resolvePermissionOverride(_overrides, role, permission);
    if (override != null) {
      return override;
    }
    return defaultPermissionsForRole(role).contains(permission);
  }

  Future<void> loadForActiveCompany() async {
    _subscription?.cancel();
    _subscription = null;
    try {
      final overrides = await loadTenantRolePermissionOverrides();
      setOverrides(overrides);
    } catch (_) {
      clear();
      return;
    }
    _subscription = streamTenantRolePermissionOverrides().listen(
      setOverrides,
      onError: (_) {},
    );
  }
}

bool hasAppPermission(UserRole? role, AppPermission permission) =>
    PermissionService.instance.hasPermission(role, permission);
