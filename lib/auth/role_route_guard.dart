import '/backend/schema/enums/enums.dart';

/// Routes drivers may access. All other authenticated routes redirect to delivery.
const kDriverAllowedRoutePaths = {
  '/',
  '/loginPage',
  '/driverDeliveryPage',
  '/orderDetailPage',
};

const _driverHomeRoutePath = '/driverDeliveryPage';
const _staffHomeRoutePath = '/salesDashBoard';

bool isRouteAllowedForRole(String path, UserRole? role) {
  if (role != UserRole.driver) {
    return true;
  }
  return kDriverAllowedRoutePaths.contains(path);
}

String defaultRoutePathForRole(UserRole? role) {
  if (role == UserRole.driver) {
    return _driverHomeRoutePath;
  }
  return _staffHomeRoutePath;
}
