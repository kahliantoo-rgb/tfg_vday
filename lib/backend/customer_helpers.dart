import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';
import '/backend/schema/customers_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

String normalizeCustomerName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String normalizeCustomerPhone(String value) =>
    value.replaceAll(RegExp(r'\D'), '');

List<CustomersRecord> filterCustomersByNameQuery(
  List<CustomersRecord> customers,
  String input, {
  int limit = 8,
}) {
  final query = normalizeCustomerName(input);
  if (query.length < 2) {
    return const [];
  }
  final matches = customers.where((customer) {
    final name = normalizeCustomerName(customer.name);
    return name.contains(query) || name.startsWith(query);
  }).toList()
    ..sort(
      (a, b) => normalizeCustomerName(a.name)
          .compareTo(normalizeCustomerName(b.name)),
    );
  if (matches.length <= limit) {
    return matches;
  }
  return matches.sublist(0, limit);
}

CustomersRecord? findExactCustomerByName(
  List<CustomersRecord> customers,
  String input,
) {
  final query = normalizeCustomerName(input);
  if (query.isEmpty) {
    return null;
  }
  for (final customer in customers) {
    if (normalizeCustomerName(customer.name) == query) {
      return customer;
    }
  }
  return null;
}

class CustomerPurchaseEntry {
  const CustomerPurchaseEntry({
    required this.order,
    required this.items,
  });

  final OrdersRecord order;
  final List<OrderItemRecord> items;

  DateTime? get purchasedAt =>
      order.deliveryDate ?? order.createdTime ?? order.deliveryTimeActual;

  String get productSummary {
    if (items.isEmpty) {
      return order.orderId.isNotEmpty ? 'Order ${order.orderId}' : 'Order';
    }
    return items
        .map((item) {
          final qty = item.qty > 0 ? '${item.qty}x ' : '';
          return '$qty${item.name}';
        })
        .join(', ');
  }
}

Future<List<CustomerPurchaseEntry>> loadCustomerPurchaseHistory(
  CustomersRecord customer, {
  int orderLimit = 50,
}) async {
  final byRef = <OrdersRecord>[];
  try {
    byRef.addAll(
      await queryTenantOrdersRecordOnce(
        queryBuilder: (query) => query
            .where('customerRef', isEqualTo: customer.reference)
            .orderBy('created_time', descending: true),
        limit: orderLimit,
      ),
    );
  } catch (_) {
    // Index may not exist yet; legacy phone/name merge below still works.
  }

  final merged = <String, OrdersRecord>{};
  for (final order in byRef) {
    merged[order.reference.path] = order;
  }

  final normalizedPhone = normalizeCustomerPhone(customer.phone);
  if (normalizedPhone.isNotEmpty) {
    final recentOrders = await queryTenantOrdersRecordOnce(
      queryBuilder: (query) =>
          query.orderBy('created_time', descending: true),
      limit: 200,
    );
    for (final order in recentOrders) {
      if (normalizeCustomerPhone(order.customerPhoneNumber) ==
              normalizedPhone ||
          normalizeCustomerName(order.clientName) ==
              normalizeCustomerName(customer.name)) {
        merged[order.reference.path] = order;
      }
    }
  }

  final orders = merged.values.toList()
    ..sort((a, b) {
      final aTime = a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  if (orders.length > orderLimit) {
    orders.removeRange(orderLimit, orders.length);
  }

  final entries = <CustomerPurchaseEntry>[];
  for (final order in orders) {
    final items = await queryTenantOrderItemRecordOnce(
      queryBuilder: (query) => query.where('orderRef', isEqualTo: order.reference),
      limit: 50,
    );
    entries.add(CustomerPurchaseEntry(order: order, items: items));
  }
  return entries;
}

Future<DocumentReference?> createCustomerProfile({
  required String name,
  required String phone,
  required String billingAddress,
}) async {
  if (TenantContext.instance.writeCompanyRef == null &&
      TenantContext.instance.activeCompanyRef == null) {
    return null;
  }
  final ref = CustomersRecord.collection.doc();
  await ref.set(
    createTenantCustomersRecordData(
      name: name.trim(),
      phone: phone.trim(),
      billingAddress: billingAddress.trim(),
      createdTime: getCurrentTimestamp,
      updatedTime: getCurrentTimestamp,
    ),
  );
  return ref;
}
