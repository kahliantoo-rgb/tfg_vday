import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/enums/enums.dart';
import '/backend/tenant_company_helpers.dart';

const _collection = 'staff_registration_intents';

/// Document id = normalized email (must match Firestore rules + Auth token email).
String staffRegistrationIntentDocId(String email) =>
    email.trim().toLowerCase();

/// Written by an admin/manager before Firebase Auth account creation.
Future<void> createStaffRegistrationIntent({
  required String email,
  required UserRole role,
  required DocumentReference companyRef,
}) async {
  final normalizedEmail = email.trim().toLowerCase();
  final docRef =
      FirebaseFirestore.instance.collection(_collection).doc(normalizedEmail);
  // Replace any stale intent from a prior failed Add Staff attempt (.set on
  // an existing doc is a rules "update", which was previously denied).
  try {
    await docRef.delete();
  } catch (_) {
    // Missing doc or offline — create may still succeed.
  }
  await docRef.set({
    'email': normalizedEmail,
    'role': role.serialize(),
    'companyRef': canonicalCompanyRef(companyRef),
    'created_time': FieldValue.serverTimestamp(),
  });
}

Future<void> deleteStaffRegistrationIntent(String email) async {
  final docId = staffRegistrationIntentDocId(email);
  await FirebaseFirestore.instance.collection(_collection).doc(docId).delete();
}
