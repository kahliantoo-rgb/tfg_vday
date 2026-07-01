import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/users_record.dart';
import 'package:tfg_vday/backend/user_list_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_test_setup.dart';

UsersRecord _user(UserRole role) => UsersRecord.getDocumentFromData(
      {'role': role, 'uid': 'u1', 'companyRef': FirebaseFirestore.instance.doc('Companies/c1')},
      FirebaseFirestore.instance.collection('users').doc('u1'),
    );

void main() {
  setUpAll(setupFirebaseForTests);

  group('canManageTargetUser', () {
    test('director can manage admin but not another director', () {
      expect(
        canManageTargetUser(
          viewerRole: UserRole.director,
          target: _user(UserRole.admin),
          viewerUid: 'director-1',
        ),
        isTrue,
      );
      expect(
        canManageTargetUser(
          viewerRole: UserRole.director,
          target: _user(UserRole.director),
          viewerUid: 'director-1',
        ),
        isFalse,
      );
    });

    test('admin cannot manage director or other admin', () {
      expect(
        canManageTargetUser(
          viewerRole: UserRole.admin,
          target: _user(UserRole.director),
          viewerUid: 'admin-1',
        ),
        isFalse,
      );
      expect(
        canManageTargetUser(
          viewerRole: UserRole.admin,
          target: _user(UserRole.florist),
          viewerUid: 'admin-1',
        ),
        isTrue,
      );
    });
  });
}
