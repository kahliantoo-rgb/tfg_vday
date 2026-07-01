import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/create_order_service.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_util.dart';

const userRegistrationRequestsCollection = 'user_registration_requests';

/// Document id = normalized email.
String userRegistrationRequestDocId(String email) =>
    email.trim().toLowerCase();

enum UserSignupAccountType {
  private,
  company,
}

String userSignupAccountTypeKey(UserSignupAccountType type) {
  switch (type) {
    case UserSignupAccountType.private:
      return 'private';
    case UserSignupAccountType.company:
      return 'company';
  }
}

UserSignupAccountType? parseUserSignupAccountType(String? raw) {
  switch (raw) {
    case 'private':
      return UserSignupAccountType.private;
    case 'company':
      return UserSignupAccountType.company;
    default:
      return null;
  }
}

String userRegistrationLogoStoragePath(String requestId, String filename) {
  final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  return 'user_registration_logos/$requestId/$safeName';
}

class UserRegistrationSubmitResult {
  const UserRegistrationSubmitResult({
    required this.success,
    this.errorMessage,
    this.requestId,
  });

  final bool success;
  final String? errorMessage;
  final String? requestId;
}

Future<UserRegistrationSubmitResult> submitUserRegistrationRequest({
  required String name,
  required String phone,
  required String email,
  DateTime? birthday,
  required UserSignupAccountType accountType,
  String? companyName,
  String? companyUen,
  String? companyAddress,
  String? companyPhone,
  String? companyEmail,
  String? companyLogoUrl,
}) async {
  final trimmedName = name.trim();
  final trimmedEmail = email.trim().toLowerCase();
  final trimmedPhone = phone.trim();

  if (trimmedName.isEmpty) {
    return const UserRegistrationSubmitResult(
      success: false,
      errorMessage: 'Please enter your name.',
    );
  }
  if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
    return const UserRegistrationSubmitResult(
      success: false,
      errorMessage: 'Please enter a valid email address.',
    );
  }
  if (trimmedPhone.isEmpty) {
    return const UserRegistrationSubmitResult(
      success: false,
      errorMessage: 'Please enter your phone number.',
    );
  }

  if (accountType == UserSignupAccountType.company) {
    final trimmedCompanyName = (companyName ?? '').trim();
    if (trimmedCompanyName.isEmpty) {
      return const UserRegistrationSubmitResult(
        success: false,
        errorMessage: 'Please enter the company name.',
      );
    }
  }

  final requestId = userRegistrationRequestDocId(trimmedEmail);
  final docRef = FirebaseFirestore.instance
      .collection(userRegistrationRequestsCollection)
      .doc(requestId);

  final existing = await docRef.get();
  if (existing.exists) {
    final status = existing.data()?['status']?.toString();
    if (status == 'pending') {
      return const UserRegistrationSubmitResult(
        success: false,
        errorMessage:
            'A registration request for this email is already pending review.',
      );
    }
    if (status == 'approved') {
      return const UserRegistrationSubmitResult(
        success: false,
        errorMessage:
            'This email is already registered. Try logging in or contact admin.',
      );
    }
  }

  final payload = <String, dynamic>{
    'email': trimmedEmail,
    'name': trimmedName,
    'phone': trimmedPhone,
    'account_type': userSignupAccountTypeKey(accountType),
    'status': 'pending',
    'created_time': FieldValue.serverTimestamp(),
  };

  if (birthday != null) {
    payload['birthday'] = birthday;
  }

  if (accountType == UserSignupAccountType.company) {
    payload['company_name'] = (companyName ?? '').trim();
    payload['company_uen'] = (companyUen ?? '').trim();
    payload['company_address'] = (companyAddress ?? '').trim();
    payload['company_phone'] = (companyPhone ?? '').trim();
    payload['company_email'] = (companyEmail ?? '').trim().toLowerCase();
    if (companyLogoUrl != null && companyLogoUrl.trim().isNotEmpty) {
      payload['company_logo_url'] = companyLogoUrl.trim();
    }
  }

  try {
    await docRef.set(payload);
    return UserRegistrationSubmitResult(
      success: true,
      requestId: requestId,
    );
  } catch (error) {
    return UserRegistrationSubmitResult(
      success: false,
      errorMessage: describeFirestoreError(error),
    );
  }
}

Future<String?> uploadUserRegistrationLogo({
  required String requestId,
  required List<int> bytes,
  required String filename,
}) async {
  final path = userRegistrationLogoStoragePath(requestId, filename);
  final result = await uploadRegistrationLogoWithResult(
    path,
    Uint8List.fromList(bytes),
  );
  if (!result.isSuccess) {
    return null;
  }
  return result.downloadUrl;
}
