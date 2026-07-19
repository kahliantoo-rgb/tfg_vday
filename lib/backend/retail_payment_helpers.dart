import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/order_discount_helpers.dart';
import '/backend/order_id_service.dart';
import '/backend/order_item_helpers.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/order_status_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_item_record.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

Future<void> completeRetailPaymentAndOpenReceipt(
  BuildContext context, {
  required DocumentReference orderRef,
  OrderPayableTotals? payableTotals,
}) async {
  final items = activeOrderItems(await queryOrderItemsForOrderOnce(orderRef));
  final orderSnap = await orderRef.get();
  final order = OrdersRecord.fromSnapshot(orderSnap);
  final orderId = OrderIdService.isRetailOrderId(order.orderId)
      ? order.orderId
      : await OrderIdService.nextRetailOrderId();

  final itemSubtotal = functions.calculationTotal(
    items.map((item) => item.price).toList(),
    items.map((item) => item.qty).toList(),
  );
  final payable = payableTotals ??
      calculateOrderPayableTotals(
        itemSubtotal: itemSubtotal,
        discount: parseOrderDiscountInput(order),
      );

  await updateOrderStatus(
    orderRef,
    OrderStatus.completed,
    extraFields: {
      ...createOrdersRecordData(
        orderId: orderId,
        deliveryDate:
            order.createdTime ?? order.deliveryDate ?? getCurrentTimestamp,
        pickupDelivery:
            order.pickupDelivery.isNotEmpty ? order.pickupDelivery : 'Retail',
      ),
      ...orderDiscountWriteData(payable),
    },
  );

  if (!context.mounted) {
    return;
  }

  context.pushNamed(
    ReceiptPreviewpage2Widget.routeName,
    queryParameters: {
      'orderRef': serializeParam(
        orderRef,
        ParamType.DocumentReference,
      )!,
      'cashier': serializeParam(
        resolvedCurrentCashierLabel(),
        ParamType.String,
      ),
    },
  );
}
