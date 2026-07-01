import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/auth/firebase_auth/email_auth.dart';
import '/auth/firebase_auth/firebase_auth_error_messages.dart';
import '/backend/staff_role_helpers.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/audit_log_service.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/auth/app_permissions.dart' as app_permissions;
import '/backend/staff_registration_intent_helpers.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/user_list_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';

/// Human-readable labels for [UserRole] in registration UI.
String userRoleLabel(UserRole role) => app_permissions.userRoleLabel(role);

/// @deprecated Use [isRoleAllowedForStaffRegistration].
bool isRoleAllowedForRegistration(UserRole role) {
  return isRoleAllowedForStaffRegistration(
    role: role,
    creatorRole: currentViewerRole(),
  );
}

class RegisterUserResult {
  const RegisterUserResult({
    required this.success,
    this.errorMessage,
    this.signedOutAdminSession = false,
  });

  final bool success;
  final String? errorMessage;

  /// True when an admin created another account and was signed out afterward.
  final bool signedOutAdminSession;
}

/// Creates Firebase Auth account and Firestore `users/{uid}` profile.
Future<RegisterUserResult> registerStaffUser({
  required BuildContext context,
  required String email,
  required String password,
  required String name,
  required UserRole role,
  required DocumentReference companyRef,
  String? phoneNumber,
}) async {
  final trimmedEmail = email.trim();
  final normalizedEmail = trimmedEmail.toLowerCase();
  final trimmedName = name.trim();

  if (trimmedName.isEmpty) {
    return const RegisterUserResult(
      success: false,
      errorMessage: 'Please enter your name.',
    );
  }
  if (trimmedEmail.isEmpty) {
    return const RegisterUserResult(
      success: false,
      errorMessage: 'Please enter your email.',
    );
  }
  if (password.length < 6) {
    return const RegisterUserResult(
      success: false,
      errorMessage: 'Password must be at least 6 characters.',
    );
  }
  if (!loggedIn || !canCreateStaffAccounts(currentViewerRole())) {
    return const RegisterUserResult(
      success: false,
      errorMessage: 'Only an administrator can create staff accounts.',
    );
  }
  if (!isRoleAllowedForStaffRegistration(
    role: role,
    creatorRole: currentViewerRole(),
    tenantRoles: await loadManagedStaffRolesWithFallback(),
  )) {
    return const RegisterUserResult(
      success: false,
      errorMessage: 'This role cannot be selected for registration.',
    );
  }

  final priorUid = loggedIn ? currentUserUid : null;

  GoRouter.of(context).prepareAuthEvent();

  try {
    await createStaffRegistrationIntent(
      email: normalizedEmail,
      role: role,
      companyRef: canonicalCompanyRef(companyRef),
    );
  } catch (e) {
    return RegisterUserResult(
      success: false,
      errorMessage: 'Could not start staff registration: $e',
    );
  }

  try {
    final credential = await emailCreateAccountFunc(normalizedEmail, password);
    if (credential?.user == null) {
      await deleteStaffRegistrationIntent(normalizedEmail);
      return const RegisterUserResult(
        success: false,
        errorMessage: 'Could not create account. Check email and password.',
      );
    }
  } on FirebaseAuthException catch (e) {
    await deleteStaffRegistrationIntent(normalizedEmail);
    if (e.code == 'email-already-in-use') {
      return const RegisterUserResult(
        success: false,
        errorMessage:
            'This email already has a Firebase login. It may exist from a '
            'previous Add Staff attempt without a staff profile. Check Firebase '
            'Console → Authentication, or run firebase/scripts/create_driver_user.js '
            'to link the profile. You can also delete the orphan Auth user and '
            'Add Staff again.',
      );
    }
    return RegisterUserResult(
      success: false,
      errorMessage: firebaseAuthErrorMessage(
        e.code,
        fallbackMessage: e.message,
      ),
    );
  }

  final uid = currentUserUid;
  if (uid.isEmpty) {
    return const RegisterUserResult(
      success: false,
      errorMessage: 'Account was created but user id is missing.',
    );
  }

  try {
    await UsersRecord.collection.doc(uid).set(
          createUsersRecordData(
            name: trimmedName,
            email: normalizedEmail,
            role: role,
            companyRef: canonicalCompanyRef(companyRef),
            uid: uid,
            displayName: trimmedName,
            createdTime: getCurrentTimestamp,
            phoneNumber: phoneNumber?.trim().isEmpty ?? true
                ? null
                : phoneNumber!.trim(),
            isActive: true,
          ),
        );
    final createdProfile =
        await UsersRecord.getDocumentOnce(UsersRecord.collection.doc(uid));
    await auditLogStaffChange(
      action: AuditLogAction.addStaff,
      user: createdProfile,
      newValue: staffAuditSnapshot(createdProfile),
      description: 'Staff account registered',
    );
    await deleteStaffRegistrationIntent(normalizedEmail);
  } catch (e) {
    return RegisterUserResult(
      success: false,
      errorMessage:
          'Account created but profile could not be saved: $e. Contact an admin.',
    );
  }

  if (priorUid != null && priorUid != uid) {
    await authManager.signOut();
    return const RegisterUserResult(
      success: true,
      signedOutAdminSession: true,
    );
  }

  return const RegisterUserResult(success: true);
}
