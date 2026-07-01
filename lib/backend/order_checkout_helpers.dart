import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/order_item_record.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/order_status_helpers.dart';

bool _companyRefsMatchForRules(
  DocumentReference? a,
  DocumentReference? b,
) {
  if (a == null || b == null) {
    return false;
  }
  if (a.path == b.path) {
    return true;
  }
  return canonicalCompanyId(a.id) == canonicalCompanyId(b.id);
}

/// Stamps [companyRef] on the order and its line items before checkout when
/// tenant isolation fields are missing or use a legacy typo company id.
Future<void> stampOrderCompanyRefBeforeCheckout(
  DocumentReference orderRef,
) async {
  final companyRef = tenantCompanyRefForRules();
  if (companyRef == null) {
    return;
  }

  final snap = await orderRef.get();
  if (!snap.exists) {
    return;
  }
  final data = snap.data() as Map<String, dynamic>? ?? {};
  final existing = data['companyRef'] as DocumentReference?;
  if (!_companyRefsMatchForRules(existing, companyRef)) {
    await orderRef.update({'companyRef': companyRef});
  }

  final itemsSnap = await OrderItemRecord.collection
      .where('orderRef', isEqualTo: orderRef)
      .limit(100)
      .get();
  for (final itemDoc in itemsSnap.docs) {
    final itemData = itemDoc.data() as Map<String, dynamic>? ?? {};
    final itemCompany = itemData['companyRef'] as DocumentReference?;
    if (_companyRefsMatchForRules(itemCompany, companyRef)) {
      continue;
    }
    await itemDoc.reference.update({'companyRef': companyRef});
  }
}

/// Builds an order update map and only sends [companyRef] when the row needs it.
Map<String, dynamic> buildOrderCheckoutPatch(
  OrdersRecord order,
  Map<String, dynamic> fields,
) {
  final patch = Map<String, dynamic>.from(fields);
  final companyRef = tenantCompanyRefForRules();
  if (companyRef == null) {
    patch.remove('companyRef');
    return patch;
  }
  final existing = order.companyRef;
  if (existing != null &&
      _companyRefsMatchForRules(existing, companyRef)) {
    patch.remove('companyRef');
    return patch;
  }
  patch['companyRef'] = companyRef;
  return patch;
}

/// Delivery detail form before checkout payment — matches [isOrderDeliveryDetailSubmitUpdate].
Future<void> submitOrderDeliveryDetailUpdate(
  DocumentReference orderRef,
  OrdersRecord order,
  Map<String, dynamic> detailFields,
) async {
  await stampOrderCompanyRefBeforeCheckout(orderRef);
  final freshOrder = await OrdersRecord.getDocumentOnce(orderRef);
  await orderRef.update(
    buildOrderCheckoutPatch(freshOrder, detailFields),
  );
}

/// Builds Firestore patch for Create Order Form submit.
Map<String, dynamic> buildOrderDeliveryDetailFields({
  required String clientName,
  required String recipientName,
  required String recipientPhoneNumber,
  required String address,
  required String postalCode,
  required String region,
  required DateTime deliveryDate,
  required String deliveryTimeSlot,
  required String cardMessage,
  required String orderType,
  required String customerPhoneNumber,
  DocumentReference? customerRef,
  DateTime? createdTime,
}) =>
    createOrdersRecordData(
      clientName: clientName,
      recipientName: recipientName,
      recipientPhoneNumber: recipientPhoneNumber,
      address: address,
      postalCode: postalCode,
      region: region,
      deliveryDate: deliveryDate,
      deliveryTimeSlot: deliveryTimeSlot,
      cardMessage: cardMessage,
      orderType: orderType,
      pickupDelivery: orderType,
      customerPhoneNumber: customerPhoneNumber,
      customerRef: customerRef,
      createdTime: createdTime,
      status: OrderStatus.pending,
      orderstatus: legacyOrderStatusLabel(OrderStatus.pending),
      companyRef: tenantCompanyRefForRules(),
    );
