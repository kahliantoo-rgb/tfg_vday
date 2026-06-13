import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

void openInvoiceProfile(
  BuildContext context,
  DocumentReference invoiceRef,
) {
  context.pushNamed(
    InvoiceProfilePageWidget.routeName,
    pathParameters: <String, String>{'invoiceId': invoiceRef.id},
    extra: <String, dynamic>{'invoiceRef': invoiceRef},
  );
}
