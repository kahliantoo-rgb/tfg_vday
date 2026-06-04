import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/role_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/users_record.dart';
import 'package:tfg_vday/backend/tenant_company_helpers.dart';
import 'package:tfg_vday/backend/user_list_helpers.dart';

import 'firebase_test_setup.dart';

UsersRecord _user({
  required String id,
  String? name,
  String? displayName,
  String? email,
  UserRole? role,
  String? companyId,
  bool? isActive,
  String? uid,
}) {
  return UsersRecord.getDocumentFromData(
    {
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (email != null) 'email': email,
      if (role != null) 'role': role.serialize(),
      if (companyId != null)
        'companyRef': FirebaseFirestore.instance
            .collection('Companies')
            .doc(companyId),
      if (isActive != null) 'is_active': isActive,
      if (uid != null) 'uid': uid,
    },
    FirebaseFirestore.instance.collection('users').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  group('canViewUserList', () {
    test('superadmin and admin can view user list', () {
      expect(canViewUserList(UserRole.superadmin), isTrue);
      expect(canViewUserList(UserRole.admin), isTrue);
    });

    test('other roles cannot view user list', () {
      expect(canViewUserList(UserRole.senior_florist), isFalse);
      expect(canViewUserList(UserRole.driver), isFalse);
      expect(canViewUserList(null), isFalse);
    });
  });

  group('userListDisplayName', () {
    test('prefers name then displayName then email', () {
      expect(
        userListDisplayName(
          _user(id: '1', name: 'Alice', displayName: 'A', email: 'a@x.com'),
        ),
        'Alice',
      );
      expect(
        userListDisplayName(
          _user(id: '2', displayName: 'Bob', email: 'b@x.com'),
        ),
        'Bob',
      );
      expect(
        userListDisplayName(_user(id: '3', email: 'c@x.com')),
        'c@x.com',
      );
    });
  });

  group('userListRoleLabel', () {
    test('maps roles to readable labels', () {
      expect(userListRoleLabel(UserRole.admin), 'Admin');
      expect(userListRoleLabel(UserRole.driver), 'Driver');
      expect(userListRoleLabel(null), '-');
    });
  });

  group('filterUsersForAdminList', () {
    test('admin sees only same-company users', () {
      final companyId = kCanonicalCompanyId;
      final users = [
        _user(id: 'a', name: 'Zoe', role: UserRole.driver, companyId: companyId),
        _user(id: 'b', name: 'Amy', role: UserRole.admin, companyId: companyId),
        _user(id: 'c', name: 'Other', role: UserRole.driver, companyId: 'other-co'),
      ];

      final filtered = filterUsersForAdminList(
        users,
        viewerRole: UserRole.admin,
        tenantCompanyId: companyId,
        isViewingAllCompanies: false,
      );

      expect(filtered.map((u) => u.reference.id).toList(), ['b', 'a']);
    });

    test('superadmin viewing all companies sees everyone sorted by name', () {
      final users = [
        _user(id: 'a', name: 'Zoe', role: UserRole.driver),
        _user(id: 'b', name: 'Amy', role: UserRole.admin),
      ];

      final filtered = filterUsersForAdminList(
        users,
        viewerRole: UserRole.superadmin,
        tenantCompanyId: '',
        isViewingAllCompanies: true,
      );

      expect(filtered.map((u) => u.name).toList(), ['Amy', 'Zoe']);
    });

    test('senior florist gets empty list', () {
      final users = [
        _user(id: 'a', name: 'Amy', role: UserRole.admin),
      ];

      expect(
        filterUsersForAdminList(
          users,
          viewerRole: UserRole.senior_florist,
          tenantCompanyId: kCanonicalCompanyId,
          isViewingAllCompanies: false,
        ),
        isEmpty,
      );
    });
  });

  group('userIsActive', () {
    test('defaults to true when field missing', () {
      expect(userIsActive(_user(id: '1', name: 'Amy')), isTrue);
    });

    test('respects is_active false', () {
      expect(
        userIsActive(_user(id: '1', name: 'Amy', isActive: false)),
        isFalse,
      );
    });
  });

  group('canManageTargetUser', () {
    test('admin cannot manage self or other admins', () {
      final self = _user(id: 'admin1', role: UserRole.admin, uid: 'admin1');
      final otherAdmin = _user(id: 'admin2', role: UserRole.admin);
      final driver = _user(id: 'd1', role: UserRole.driver);

      expect(
        canManageTargetUser(
          viewerRole: UserRole.admin,
          target: self,
          viewerUid: 'admin1',
        ),
        isFalse,
      );
      expect(
        canManageTargetUser(
          viewerRole: UserRole.admin,
          target: otherAdmin,
          viewerUid: 'admin1',
        ),
        isFalse,
      );
      expect(
        canManageTargetUser(
          viewerRole: UserRole.admin,
          target: driver,
          viewerUid: 'admin1',
        ),
        isTrue,
      );
    });

    test('superadmin can manage others but not self', () {
      final self = _user(id: 'sa1', role: UserRole.superadmin, uid: 'sa1');
      final admin = _user(id: 'a1', role: UserRole.admin);

      expect(
        canManageTargetUser(
          viewerRole: UserRole.superadmin,
          target: self,
          viewerUid: 'sa1',
        ),
        isFalse,
      );
      expect(
        canManageTargetUser(
          viewerRole: UserRole.superadmin,
          target: admin,
          viewerUid: 'sa1',
        ),
        isTrue,
      );
    });
  });
}
