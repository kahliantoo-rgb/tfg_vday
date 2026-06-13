import '/backend/backend.dart';
import '/backend/driver_route_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_list_helpers.dart';

Future<List<UsersRecord>> queryTenantDriversOnce() async {
  final companyId = TenantContext.instance.writeCompanyId;
  final all = await queryUsersRecordOnce(
    queryBuilder: (q) =>
        q.where('role', isEqualTo: UserRole.driver.serialize()),
  );
  final drivers = all.where((user) {
    if (!userIsActive(user)) {
      return false;
    }
    if (companyId.isEmpty) {
      return true;
    }
    return canonicalCompanyId(user.companyRef?.id) == companyId;
  }).toList()
    ..sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  return drivers;
}

List<OrdersRecord> suggestedRouteOrders(List<OrdersRecord> orders) =>
    sortOrdersForDriverRoute(orders);

String driverDisplayName(UsersRecord driver) {
  if (driver.name.trim().isNotEmpty) {
    return driver.name.trim();
  }
  if (driver.email.trim().isNotEmpty) {
    return driver.email.trim();
  }
  return driver.reference.id;
}
