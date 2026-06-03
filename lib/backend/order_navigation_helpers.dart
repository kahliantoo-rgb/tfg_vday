import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

Map<String, String> orderRefQueryParams(DocumentReference orderRef) {
  final serialized = serializeParam(
    orderRef,
    ParamType.DocumentReference,
  );
  if (serialized == null) {
    return const <String, String>{};
  }
  return <String, String>{'orderRef': serialized};
}

Map<String, dynamic> orderRefExtra(DocumentReference orderRef) =>
    <String, dynamic>{'orderRef': orderRef};

/// Opens order detail (status, edit, reprint, delivery summary).
void openOrderDetail(
  BuildContext context,
  DocumentReference orderRef,
) {
  context.pushNamed(
    OrderDetailPageWidget.routeName,
    queryParameters: orderRefQueryParams(orderRef),
    extra: orderRefExtra(orderRef),
  );
}

/// Opens order list; tapping a row navigates to [openOrderDetail].
void openOrderList(BuildContext context) {
  context.pushNamed(OrderlistWidget.routeName);
}

/// After saving delivery details, land on order detail (not delivery order page).
void finishDeliveryDetailsAndShowOrderDetail(
  BuildContext context,
  DocumentReference orderRef,
) {
  if (context.mounted) {
    context.pop();
  }
  if (context.mounted) {
    openOrderDetail(context, orderRef);
  }
}
