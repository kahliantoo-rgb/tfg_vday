import 'dart:async';

import 'package:flutter/foundation.dart';

import '/auth/app_permissions.dart';
import '/backend/role_permissions_helpers.dart';
import '/backend/user_permissions_helpers.dart';
import '/backend/schema/enums/enums.dart';

/// Company-scoped permission overrides loaded from Firestore.
class PermissionService extends ChangeNotifier {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  RolePermissionOverrides _overrides = {};
  UserPermissionOverrides _userOverrides = {};
  StreamSubscription<RolePermissionOverrides>? _subscription;

  RolePermissionOverrides get overrides => _overrides;
  UserPermissionOverrides get userOverrides => _userOverrides;

  void setOverrides(RolePermissionOverrides overrides) {
    _overrides = overrides;
    notifyListeners();
  }

  void applyUserProfile(UserPermissionOverrides userOverrides) {
    _userOverrides = userOverrides;
    notifyListeners();
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _overrides = {};
    _userOverrides = {};
    notifyListeners();
  }

  bool hasPermission(UserRole? role, AppPermission permission) =>
      effectivePermissionForUser(
        role: role,
        permission: permission,
        roleOverrides: _overrides,
        userOverrides: _userOverrides,
      );

  bool permissionForRole(UserRole role, AppPermission permission) {
    return effectivePermissionForUser(
      role: role,
      permission: permission,
      roleOverrides: _overrides,
      userOverrides: _userOverrides,
    );
  }

  Future<void> loadForActiveCompany() async {
    _subscription?.cancel();
    _subscription = null;
    try {
      final overrides = await loadTenantRolePermissionOverrides();
      setOverrides(overrides);
    } catch (_) {
      _overrides = {};
      notifyListeners();
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
