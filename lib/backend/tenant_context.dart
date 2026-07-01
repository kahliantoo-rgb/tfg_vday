import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/app_state.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/enums/enums.dart';
import '/auth/role_helpers.dart';
import '/backend/schema/users_record.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/backend/user_permissions_helpers.dart';
import '/auth/permission_service.dart';

/// Active company (tenant) for writes and optional read filter.
class TenantContext extends ChangeNotifier {
  TenantContext._();

  static final TenantContext instance = TenantContext._();

  DocumentReference? _activeCompanyRef;
  CompaniesRecord? _activeCompany;
  bool _viewAllCompanies = true;
  UsersRecord? _profile;

  UsersRecord? get profile => _profile;
  UserRole? get profileRole => _profile?.role;

  DocumentReference? get activeCompanyRef => _activeCompanyRef;
  CompaniesRecord? get activeCompany => _activeCompany;
  bool get hasActiveCompany => _activeCompanyRef != null;

  /// Company used for new orders/counters (staff: always profile company).
  DocumentReference? get writeCompanyRef {
    if (_profile != null && !canViewAllCompanies(_profile)) {
      return canonicalCompanyRef(_profile!.companyRef ?? _activeCompanyRef);
    }
    return canonicalCompanyRef(_activeCompanyRef);
  }

  /// Canonical companyRef for tenant writes (matches backfilled production data).
  DocumentReference? get rulesMatchedCompanyRef {
    if (_profile != null && !canViewAllCompanies(_profile)) {
      return canonicalCompanyRef(_profile!.companyRef ?? _activeCompanyRef);
    }
    return writeCompanyRef;
  }

  String get writeCompanyId => canonicalCompanyId(writeCompanyRef?.id);
  bool get isViewingAllCompanies => _viewAllCompanies;
  bool get isFilteringByCompany =>
      !_viewAllCompanies && _activeCompanyRef != null;

  /// Label for the app bar / filter chip.
  String get viewScopeLabel {
    if (isViewingAllCompanies) {
      return 'All companies';
    }
    return activeCompany?.companyName.isNotEmpty == true
        ? activeCompany!.companyName
        : 'One company';
  }

  static bool canViewAllCompanies(UsersRecord? profile) =>
      isSuperAdminRole(profile?.role);

  /// Restores tenant from storage, then user profile.
  Future<void> initialize(UsersRecord? profile) async {
    _profile = profile;
    PermissionService.instance.applyUserProfile(
      parseUserPermissionOverrides(profile),
    );
    await FFAppState().initializePersistedState();
    _viewAllCompanies = FFAppState().viewAllCompanies;

    // Superadmin always opens in cross-company read mode (writes still use active company if set).
    if (isSuperAdminRole(profile?.role)) {
      final storedPath = FFAppState().selectedCompanyPath;
      if (storedPath.isNotEmpty) {
        _activeCompanyRef = canonicalCompanyRef(
          FirebaseFirestore.instance.doc(storedPath),
        );
        await _loadActiveCompany();
      }
      _viewAllCompanies = true;
      FFAppState().viewAllCompanies = true;
      await PermissionService.instance.loadForActiveCompany();
      return;
    }

    // Single-company roles: always use profile company (ignore stale device cache).
    _viewAllCompanies = false;
    FFAppState().viewAllCompanies = false;
    await _maybeRepairTypoCompanyRefOnProfile(profile);
    final profileCompany = canonicalCompanyRef(profile?.companyRef);
    if (profile?.companyRef != null) {
      final needsRebind = !hasActiveCompany ||
          _activeCompanyRef!.path != profileCompany.path;
      if (needsRebind) {
        await setActiveCompany(profileCompany, viewAll: false);
      }
    } else if (FFAppState().selectedCompanyPath.contains(kTypoCompanyId)) {
      FFAppState().selectedCompanyPath = '';
      await setActiveCompany(profileCompany, viewAll: false);
    }
    await PermissionService.instance.loadForActiveCompany();
  }

  /// View all companies (no read filter). Writes still need [setActiveCompany].
  Future<void> setViewAllCompanies() async {
    _viewAllCompanies = true;
    FFAppState().viewAllCompanies = true;
    notifyListeners();
  }

  /// View/filter one company. Also used as write context for new orders.
  Future<void> setActiveCompany(
    DocumentReference companyRef, {
    bool viewAll = false,
  }) async {
    _activeCompanyRef = companyRef;
    FFAppState().selectedCompanyPath = companyRef.path;
    _viewAllCompanies = viewAll;
    FFAppState().viewAllCompanies = viewAll;
    await _loadActiveCompany();
    await PermissionService.instance.loadForActiveCompany();
    notifyListeners();
  }

  Future<void> clearActiveCompany() async {
    _activeCompanyRef = null;
    _activeCompany = null;
    FFAppState().selectedCompanyPath = '';
    notifyListeners();
  }

  Future<void> reloadActiveCompany() async {
    await _loadActiveCompany();
    notifyListeners();
  }

  Future<void> _loadActiveCompany() async {
    final ref = _activeCompanyRef;
    if (ref == null) {
      _activeCompany = null;
      return;
    }
    try {
      _activeCompany = await CompaniesRecord.getDocumentOnce(ref);
    } catch (_) {
      _activeCompany = null;
    }
  }

  /// Firestore rules compare raw profile companyRef; orders use [canonicalCompanyRef].
  Future<void> _maybeRepairTypoCompanyRefOnProfile(UsersRecord? profile) async {
    final rawRef = profile?.companyRef;
    if (profile == null || rawRef == null || !isTypoCompanyId(rawRef.id)) {
      return;
    }
    final canonical = canonicalCompanyRef(rawRef);
    try {
      await profile.reference.update({'companyRef': canonical});
      _profile = await UsersRecord.getDocumentOnce(profile.reference);
    } catch (_) {
      // Rules or offline — writes still use canonical via [writeCompanyRef].
    }
  }

  /// Ensures users/{auth.uid} carries role + companyRef for Firestore rules.
  Future<void> _ensureAuthUidProfileSynced(UsersRecord profile) async {
    final uid = currentUserUid;
    if (uid.isEmpty) {
      return;
    }
    final authRef = UsersRecord.collection.doc(uid);
    final canonical = canonicalCompanyRef(profile.companyRef);
    if (canonical == null) {
      return;
    }
    final needsSync = profile.reference.path != authRef.path ||
        !profile.hasCompanyRef() ||
        (profile.hasCompanyRef() && isTypoCompanyId(profile.companyRef!.id));
    if (!needsSync && profile.reference.path == authRef.path) {
      return;
    }
    try {
      await authRef.set(
        {
          if (profile.hasRole()) 'role': profile.role!.serialize(),
          'companyRef': canonical,
          if (profile.email.isNotEmpty) 'email': profile.email,
          'uid': uid,
        },
        SetOptions(merge: true),
      );
      _profile = await UsersRecord.getDocumentOnce(authRef);
    } catch (_) {
      // Offline or rules — checkout may still fail until profile is fixed.
    }
  }

  /// Ensures profile + active company are ready before tenant-scoped writes.
  /// Returns a user-facing message when blocked, or null when OK to proceed.
  Future<String?> ensureReadyForTenantWrite() async {
    var profile = _profile;
    if (profile == null) {
      profile = await resolveCurrentUserProfile();
      if (profile != null) {
        await initialize(profile);
      }
    }

    if (profile == null) {
      return 'User profile not found. Ask admin to set up users/{uid}.';
    }

    if (!canViewAllCompanies(profile)) {
      await _ensureAuthUidProfileSynced(profile);
      profile = _profile ?? profile;
    }

    if (canViewAllCompanies(profile)) {
      if (!hasActiveCompany) {
        return 'Select a company first (Company menu in the app bar).';
      }
      return null;
    }

    await _maybeRepairTypoCompanyRefOnProfile(profile);
    profile = _profile ?? profile;

    if (profile.companyRef == null) {
      return 'Your user profile has no company. Ask admin to set companyRef.';
    }
    final companyRef = canonicalCompanyRef(profile.companyRef);
    if (!hasActiveCompany || _activeCompanyRef!.path != companyRef.path) {
      await setActiveCompany(companyRef, viewAll: false);
    }

    return null;
  }

  /// Ensures profile + active company are ready before creating an order.
  /// Returns a user-facing message when blocked, or null when OK to proceed.
  Future<String?> ensureReadyForNewOrder() async {
    final blocked = await ensureReadyForTenantWrite();
    if (blocked == null) {
      return null;
    }
    if (blocked.startsWith('Select a company')) {
      return 'Select a company for this order (Company menu in the app bar).';
    }
    return blocked;
  }

  /// Only non–cross-company users must pick a company before using the app.
  bool needsCompanySelection(UsersRecord? profile) {
    if (canViewAllCompanies(profile)) {
      return false;
    }
    if (hasActiveCompany) {
      return false;
    }
    if (profile?.companyRef != null) {
      return false;
    }
    return true;
  }

  /// Companies visible on the selection screen.
  Query Function(Query) companiesQueryForUser(UsersRecord? profile) {
    return (Query query) {
      query = query.where('is_active', isEqualTo: true);
      if (!canViewAllCompanies(profile) && profile?.companyRef != null) {
        query = query.where(
          FieldPath.documentId,
          isEqualTo: profile!.companyRef!.id,
        );
      }
      // Sort client-side — composite index on is_active + Company_name is not required.
      return query;
    };
  }
}
