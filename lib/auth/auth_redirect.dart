import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/user_query_helpers.dart';
import '/index.dart';

/// Resolves the home route after login based on user role.
Future<String> getPostLoginRoutePath() async {
  if (!loggedIn) {
    return LoginPageWidget.routePath;
  }

  final profile = await resolveCurrentUserProfile();

  if (profile?.role == UserRole.driver) {
    return DriverDeliveryPageWidget.routePath;
  }

  return SalesDashBoardWidget.routePath;
}

Future<UserRole?> getCurrentUserRole() async {
  final profile = await resolveCurrentUserProfile();
  return profile?.role;
}
