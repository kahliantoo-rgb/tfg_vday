import '/auth/role_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/users_record.dart';
import '/backend/tenant_company_helpers.dart';

String userListDisplayName(UsersRecord user) {
  if (user.name.trim().isNotEmpty) {
    return user.name.trim();
  }
  if (user.displayName.trim().isNotEmpty) {
    return user.displayName.trim();
  }
  if (user.email.trim().isNotEmpty) {
    return user.email.trim();
  }
  return 'Unknown user';
}

String userListRoleLabel(UserRole? role) {
  switch (role) {
    case UserRole.superadmin:
      return 'Super Admin';
    case UserRole.admin:
      return 'Admin';
    case UserRole.senior_florist:
      return 'Senior Florist';
    case UserRole.driver:
      return 'Driver';
    case null:
      return '-';
  }
}

bool userIsActive(UsersRecord user) => user.isActive;

String userListStatusLabel(UsersRecord user) =>
    userIsActive(user) ? 'Active' : 'Inactive';

bool isSameUserProfile(UsersRecord user, String? viewerUid) {
  if (viewerUid == null || viewerUid.isEmpty) {
    return false;
  }
  return user.uid == viewerUid || user.reference.id == viewerUid;
}

/// Whether [viewerRole] may deactivate/delete [target] from the admin user list.
bool canManageTargetUser({
  required UserRole? viewerRole,
  required UsersRecord target,
  required String? viewerUid,
}) {
  if (!canViewUserList(viewerRole)) {
    return false;
  }
  if (isSameUserProfile(target, viewerUid)) {
    return false;
  }
  if (isSuperAdminRole(viewerRole)) {
    return true;
  }
  if (isCompanyAdminRole(viewerRole)) {
    return !isSuperAdminRole(target.role) && !isCompanyAdminRole(target.role);
  }
  return false;
}

List<UsersRecord> manageableUsersFromSelection({
  required List<UsersRecord> users,
  required Set<String> selectedIds,
  required UserRole? viewerRole,
  required String? viewerUid,
}) {
  return users
      .where(
        (user) =>
            selectedIds.contains(user.reference.id) &&
            canManageTargetUser(
              viewerRole: viewerRole,
              target: user,
              viewerUid: viewerUid,
            ),
      )
      .toList();
}

List<UsersRecord> filterUsersForAdminList(
  List<UsersRecord> users, {
  required UserRole? viewerRole,
  required String tenantCompanyId,
  required bool isViewingAllCompanies,
}) {
  if (!canViewUserList(viewerRole)) {
    return const [];
  }

  Iterable<UsersRecord> filtered;
  if (isSuperAdminRole(viewerRole) && isViewingAllCompanies) {
    filtered = users;
  } else {
    if (tenantCompanyId.isEmpty) {
      return const [];
    }
    filtered = users.where((user) {
      if (!user.hasCompanyRef()) {
        return false;
      }
      return canonicalCompanyId(user.companyRef?.id) == tenantCompanyId;
    });
  }

  final list = filtered.toList()
    ..sort(
      (a, b) => userListDisplayName(a)
          .toLowerCase()
          .compareTo(userListDisplayName(b).toLowerCase()),
    );
  return list;
}
