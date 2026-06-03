import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';

/// Resolves the home route after login based on user role and tenant.
Future<String> getPostLoginRoutePath() async {
  if (!loggedIn) {
    return LoginPageWidget.routePath;
  }

  final profile = await resolveCurrentUserProfile();
  await TenantContext.instance.initialize(profile);
  AppStateNotifier.instance.syncUserRole(profile?.role);

  if (profile?.role == UserRole.driver) {
    return DriverDeliveryPageWidget.routePath;
  }

  if (TenantContext.instance.needsCompanySelection(profile)) {
    return CompanySelectionPageWidget.routePath;
  }

  return SalesDashBoardWidget.routePath;
}

Future<UserRole?> getCurrentUserRole() async {
  final profile = await resolveCurrentUserProfile();
  return profile?.role;
}
