import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Loads one order by [orderRef] — use instead of queryOrdersRecord(singleRecord: true).
class OrderRecordBuilder extends StatelessWidget {
  const OrderRecordBuilder({
    super.key,
    required this.orderRef,
    required this.builder,
    this.loading,
  });

  final DocumentReference orderRef;
  final Widget Function(BuildContext context, OrdersRecord order) builder;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrdersRecord>(
      stream: OrdersRecord.getDocument(orderRef),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return loading ??
              Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
              );
        }
        return builder(context, snapshot.data!);
      },
    );
  }
}

Stream<OrdersRecord> streamOrderByRef(DocumentReference orderRef) =>
    OrdersRecord.getDocument(orderRef);
