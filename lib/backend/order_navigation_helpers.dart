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

/// Full delivery — delivery order summary (print, assign driver, etc.).
void openFullDeliverySummary(
  BuildContext context,
  DocumentReference orderRef,
) {
  context.pushNamed(
    DeliveryOrderSummaryPageWidget.routeName,
    queryParameters: orderRefQueryParams(orderRef),
    extra: orderRefExtra(orderRef),
  );
}

/// Record partial delivery (e.g. 5 of 10 items today).
void openPartialDelivery(
  BuildContext context,
  DocumentReference orderRef,
) {
  context.pushNamed(
    PartialDeliveryPageWidget.routeName,
    queryParameters: orderRefQueryParams(orderRef),
    extra: orderRefExtra(orderRef),
  );
}

enum DeliveryModeChoice {
  full,
  partial,
}

/// Full delivery vs partial delivery before opening the fulfilment flow.
Future<DeliveryModeChoice?> showDeliveryModePickerDialog(
  BuildContext context,
) async {
  return showDialog<DeliveryModeChoice>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Delivery type'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, DeliveryModeChoice.full),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.local_shipping_outlined),
            title: Text('Full delivery'),
            subtitle: Text('Delivery order summary and print'),
          ),
        ),
        SimpleDialogOption(
          onPressed: () =>
              Navigator.pop(dialogContext, DeliveryModeChoice.partial),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.inventory_2_outlined),
            title: Text('Partial delivery'),
            subtitle: Text('Deliver selected quantities only'),
          ),
        ),
      ],
    ),
  );
}

/// Delivery Order button entry: pick full vs partial, then navigate.
Future<void> runDeliveryOrderFlow(
  BuildContext context,
  DocumentReference orderRef,
) async {
  final choice = await showDeliveryModePickerDialog(context);
  if (choice == null || !context.mounted) {
    return;
  }
  switch (choice) {
    case DeliveryModeChoice.full:
      openFullDeliverySummary(context, orderRef);
    case DeliveryModeChoice.partial:
      openPartialDelivery(context, orderRef);
  }
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
