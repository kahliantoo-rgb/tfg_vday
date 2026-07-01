import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/users_record.dart';

/// Loads the signed-in user's profile from Firestore.
/// Order: users/{auth.uid} doc id (rules canonical), uid field query, email query.
Future<UsersRecord?> resolveCurrentUserProfile() async {
  if (!loggedIn) {
    return null;
  }

  if (currentUserUid.isNotEmpty) {
    final docRef = UsersRecord.collection.doc(currentUserUid);
    try {
      final byDocId = await UsersRecord.getDocumentOnce(docRef);
      // Rules read users/{auth.uid} only — incomplete uid docs must fall through.
      if (byDocId.hasCompanyRef() && byDocId.hasRole()) {
        return byDocId;
      }
    } catch (_) {
      // Doc missing or permission denied — fall through to queries.
    }

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
