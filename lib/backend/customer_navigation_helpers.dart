import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

Map<String, dynamic> customerRefExtra(DocumentReference customerRef) =>
    <String, dynamic>{'customerRef': customerRef};

/// Opens customer profile; completes when the profile route is popped or left.
Future<void> openCustomerProfile(
  BuildContext context,
  DocumentReference customerRef,
) {
  return context.pushNamed(
    CustomerProfilePageWidget.routeName,
    pathParameters: <String, String>{'customerId': customerRef.id},
    extra: customerRefExtra(customerRef),
  );
}

/// Back from profile/create/edit — pop when possible, else open customer list.
void exitCustomerFlow(BuildContext context, {Object? result}) {
  if (context.canPop()) {
    context.pop(result);
    return;
  }
  context.go(CustomerListPageWidget.routePath);
}

/// After delete or back from profile, open a fresh customer list (reliable on web).
void goToCustomerList(BuildContext context) {
  if (!context.mounted) {
    return;
  }
  context.go(CustomerListPageWidget.routePath);
}

/// Profile app bar back — always return to customer list.
void exitCustomerProfile(BuildContext context) {
  goToCustomerList(context);
}
