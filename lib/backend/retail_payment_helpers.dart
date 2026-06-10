import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/order_id_service.dart';
import '/backend/order_item_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

Future<void> completeRetailPaymentAndOpenReceipt(
  BuildContext context, {
  required DocumentReference orderRef,
}) async {
  final items = activeOrderItems(
    await queryOrderItemRecordOnce(
      queryBuilder: (query) => query.where('orderRef', isEqualTo: orderRef),
    ),
  );
  final orderSnap = await orderRef.get();
  final order = OrdersRecord.fromSnapshot(orderSnap);
  final orderId = OrderIdService.isRetailOrderId(order.orderId)
      ? order.orderId
      : await OrderIdService.nextRetailOrderId();

  await orderRef.update(
    createOrdersRecordData(
      totalAmount: functions.calculationTotal(
        items.map((item) => item.price).toList(),
        items.map((item) => item.qty).toList(),
      ),
      orderId: orderId,
      deliveryDate:
          order.createdTime ?? order.deliveryDate ?? getCurrentTimestamp,
      pickupDelivery:
          order.pickupDelivery.isNotEmpty ? order.pickupDelivery : 'Retail',
    ),
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
    },
  );
}
