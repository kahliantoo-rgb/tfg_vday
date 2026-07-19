import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/cash_payment_helpers.dart';
import '/components/outstanding_balance_dialog.dart';
import '/backend/order_status_display.dart';
import '/backend/order_status_helpers.dart';
import '/backend/order_whatsapp_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'update_order_status_model.dart';
export 'update_order_status_model.dart';

class UpdateOrderStatusWidget extends StatefulWidget {
  const UpdateOrderStatusWidget({
    super.key,
    required this.orderRef,
  });

  final DocumentReference? orderRef;

  @override
  State<UpdateOrderStatusWidget> createState() =>
      _UpdateOrderStatusWidgetState();
}

class _UpdateOrderStatusWidgetState extends State<UpdateOrderStatusWidget> {
  late UpdateOrderStatusModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UpdateOrderStatusModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  Future<void> _applyStatus(OrderStatus status) async {
    if (status == OrderStatus.ready_to_delivery ||
        status == OrderStatus.completed) {
      final order = await OrdersRecord.getDocumentOnce(widget.orderRef!);
      final saleTotal = await loadOrderSaleTotal(widget.orderRef!);
      if (mounted) {
        await showBalanceDueReminderDialog(
          context,
          order: order,
          targetStatus: status,
          saleTotal: saleTotal,
        );
      }
    }

    await updateOrderStatus(widget.orderRef!, status);
    await auditLogOrderStatusChangeByRef(widget.orderRef!, status);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Color _buttonColor(OrderStatus status) {
    final theme = FlutterFlowTheme.of(context);
    switch (status) {
      case OrderStatus.processing:
        return theme.secondary;
      case OrderStatus.ready_to_delivery:
        return theme.accent1;
      case OrderStatus.out_of_delivery:
        return theme.warning;
      case OrderStatus.completed:
        return theme.success;
      case OrderStatus.cancelled:
        return theme.error;
      case OrderStatus.pending:
        return theme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 5.0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
              child: Container(
                width: 50.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    tr(context, 'order.statusSheet.title'),
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          font: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500,
                          ),
                          color: const Color(0xFF14181B),
                          fontSize: 24.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
              child: StreamBuilder<OrdersRecord>(
                stream: OrdersRecord.getDocument(widget.orderRef!),
                builder: (context, snapshot) {
                  final isPickup = snapshot.hasData &&
                      isPickupOrderRecord(snapshot.data!);
                  final statuses =
                      orderStatusUpdateOptions(isPickup: isPickup);
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    primary: false,
                    shrinkWrap: true,
                    itemCount: statuses.length,
                    itemBuilder: (context, index) {
                      final status = statuses[index];
                      return Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16.0,
                          12.0,
                          16.0,
                          0.0,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 50.0,
                          decoration: BoxDecoration(
                            color: _buttonColor(status),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: const Color(0xFFE0E3E7),
                              width: 2.0,
                            ),
                          ),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              await _applyStatus(status);
                            },
                            child: Text(
                              orderStatusDisplayLabel(
                                context,
                                status,
                                isPickup: isPickup,
                              ),
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(),
                                    fontSize: 30.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
