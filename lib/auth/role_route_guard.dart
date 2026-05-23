import '/backend/schema/enums/enums.dart';
import '/index.dart';

/// Routes drivers may access. All other authenticated routes redirect to delivery.
const kDriverAllowedRoutePaths = {
  '/',
  LoginPageWidget.routePath,
  DriverDeliveryPageWidget.routePath,
};

bool isRouteAllowedForRole(String path, UserRole? role) {
  if (role != UserRole.driver) {
    return true;
  }
  return kDriverAllowedRoutePaths.contains(path);
}

String defaultRoutePathForRole(UserRole? role) {
  if (role == UserRole.driver) {
    return DriverDeliveryPageWidget.routePath;
  }
  return SalesDashBoardWidget.routePath;
}
