import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/app_state.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/enums/enums.dart';
import '/auth/role_helpers.dart';
import '/backend/schema/users_record.dart';

/// Active company (tenant) for writes and optional read filter.
class TenantContext extends ChangeNotifier {
  TenantContext._();

  static final TenantContext instance = TenantContext._();

  DocumentReference? _activeCompanyRef;
  CompaniesRecord? _activeCompany;
  bool _viewAllCompanies = true;
  UsersRecord? _profile;

  DocumentReference? get activeCompanyRef => _activeCompanyRef;
  CompaniesRecord? get activeCompany => _activeCompany;
  bool get hasActiveCompany => _activeCompanyRef != null;
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
    await FFAppState().initializePersistedState();
    _viewAllCompanies = FFAppState().viewAllCompanies;

    final storedPath = FFAppState().selectedCompanyPath;
    if (storedPath.isNotEmpty) {
      _activeCompanyRef = FirebaseFirestore.instance.doc(storedPath);
      await _loadActiveCompany();
    }

    // Superadmin always opens in cross-company read mode (writes still use active company if set).
    if (isSuperAdminRole(profile?.role)) {
      _viewAllCompanies = true;
      FFAppState().viewAllCompanies = true;
      return;
    }

    // Single-company roles: bind to profile company.
    _viewAllCompanies = false;
    FFAppState().viewAllCompanies = false;
    if (!hasActiveCompany && profile?.companyRef != null) {
      await setActiveCompany(profile!.companyRef!, viewAll: false);
    }
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
    notifyListeners();
  }

  Future<void> clearActiveCompany() async {
    _activeCompanyRef = null;
    _activeCompany = null;
    FFAppState().selectedCompanyPath = '';
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
      return query.orderBy('Company_name');
    };
  }
}
