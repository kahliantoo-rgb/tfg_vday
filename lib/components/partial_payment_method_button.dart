import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/cash_payment_helpers.dart';
import '/backend/order_balance_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class PartialPaymentMethodButton extends StatelessWidget {
  const PartialPaymentMethodButton({
    super.key,
    required this.orderRef,
    required this.paymentType,
    required this.label,
    required this.icon,
    required this.currentPaymentType,
    this.saleTotal,
    this.onFullyPaid,
    this.pendingSelection,
    this.onSelectionChanged,
    this.width = 80,
    this.height = 75.1,
    this.useBodySmall = false,
  });

  final DocumentReference orderRef;
  final String paymentType;
  final String label;
  final Widget icon;
  final String? currentPaymentType;
  final double? saleTotal;
  final Future<void> Function(PaymentApplicationResult applied)? onFullyPaid;
  final PendingOrderPaymentSelection? pendingSelection;
  final ValueChanged<PendingOrderPaymentSelection>? onSelectionChanged;
  final double width;
  final double height;
  final bool useBodySmall;

  bool get _selectionOnly => onSelectionChanged != null;

  bool get _selected {
    if (pendingSelection?.paymentType == paymentType) {
      return true;
    }
    return !_selectionOnly && currentPaymentType == paymentType;
  }

  Future<void> _onPressed(BuildContext context) async {
    if (_selectionOnly) {
      final selection = await selectPartialPaymentForSummary(
        context,
        orderRef: orderRef,
        paymentType: paymentType,
        paymentLabel: label,
        saleTotal: saleTotal,
      );
      if (selection != null && context.mounted) {
        onSelectionChanged!(selection);
      }
      return;
    }

    await handlePaymentMethodSelection(
      context,
      orderRef: orderRef,
      paymentType: paymentType,
      paymentLabel: label,
      saleTotal: saleTotal,
      onFullyPaid: onFullyPaid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final textStyle = (useBodySmall ? theme.bodySmall : theme.bodyMedium)
        .override(
      font: GoogleFonts.inter(
        fontWeight: useBodySmall ? FontWeight.w500 : theme.bodyMedium.fontWeight,
        fontStyle: useBodySmall
            ? theme.bodySmall.fontStyle
            : theme.bodyMedium.fontStyle,
      ),
      color: useBodySmall ? theme.secondaryText : null,
      letterSpacing: 0.0,
      fontWeight: useBodySmall ? FontWeight.w500 : theme.bodyMedium.fontWeight,
      fontStyle: useBodySmall
          ? theme.bodySmall.fontStyle
          : theme.bodyMedium.fontStyle,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onPressed(context),
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: _selected ? theme.accent1 : theme.primaryBackground,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: _selected ? theme.primary : theme.alternate,
              width: _selected ? 2.0 : 1.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(useBodySmall ? 6.0 : 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: useBodySmall ? 40.0 : 35.0,
                  height: useBodySmall ? 40.0 : 35.0,
                  decoration: BoxDecoration(
                    color: _selected ? theme.tertiary : theme.accent3,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
                Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
