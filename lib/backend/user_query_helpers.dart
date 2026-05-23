import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/users_record.dart';

/// Loads the signed-in user's profile from Firestore (uid, then email).
Future<UsersRecord?> resolveCurrentUserProfile() async {
  if (!loggedIn) {
    return null;
  }

  if (currentUserUid.isNotEmpty) {
    final byUid = await queryUsersRecordOnce(
      queryBuilder: (q) => q.where('uid', isEqualTo: currentUserUid).limit(1),
    );
    if (byUid.isNotEmpty) {
      return byUid.first;
    }
  }

  if (currentUserEmail.isNotEmpty) {
    final byEmail = await queryUsersRecordOnce(
      queryBuilder: (q) => q.where('email', isEqualTo: currentUserEmail).limit(1),
    );
    if (byEmail.isNotEmpty) {
      return byEmail.first;
    }
  }

  return null;
}

Stream<UsersRecord?> streamCurrentUserProfile() async* {
  final profile = await resolveCurrentUserProfile();
  yield profile;
}
