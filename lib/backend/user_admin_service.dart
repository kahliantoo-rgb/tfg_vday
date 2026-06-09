import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/enums/enums.dart';
import '/backend/schema/users_record.dart';

Future<int> setUsersActiveStatus({
  required List<UsersRecord> users,
  required bool isActive,
}) async {
  if (users.isEmpty) {
    return 0;
  }

  final batch = FirebaseFirestore.instance.batch();
  for (final user in users) {
    batch.update(user.reference, {'is_active': isActive});
  }
  await batch.commit();
  return users.length;
}

Future<int> deleteUserProfiles({
  required List<UsersRecord> users,
}) async {
  if (users.isEmpty) {
    return 0;
  }

  final batch = FirebaseFirestore.instance.batch();
  for (final user in users) {
    batch.delete(user.reference);
  }
  await batch.commit();
  return users.length;
}

Future<void> updateUserProfile({
  required UsersRecord user,
  required String name,
  required UserRole role,
  String? phoneNumber,
}) async {
  final trimmedName = name.trim();
  await user.reference.update(
    createUsersRecordData(
      name: trimmedName,
      displayName: trimmedName,
      role: role,
      phoneNumber: phoneNumber?.trim().isEmpty ?? true
          ? null
          : phoneNumber!.trim(),
    ),
  );
}
