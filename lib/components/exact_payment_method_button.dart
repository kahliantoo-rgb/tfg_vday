import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/cash_payment_helpers.dart';
import '/backend/order_balance_helpers.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Payment methods that apply the remaining balance immediately (no amount dialog).
class ExactPaymentMethodButton extends StatelessWidget {
  const ExactPaymentMethodButton({
    super.key,
    required this.orderRef,
    required this.paymentType,
    required this.label,
    required this.icon,
    required this.currentPaymentType,
    this.saleTotal,
    this.onFullyPaid,
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
  final double width;
  final double height;
  final bool useBodySmall;

  bool get _selected => currentPaymentType == paymentType;

  Future<void> _onPressed(BuildContext context) async {
    await handleExactPaymentMethodSelection(
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

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(width: 2.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(useBodySmall ? 6.0 : 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterFlowIconButton(
              borderRadius: 8.0,
              buttonSize: useBodySmall ? 40.0 : 35.0,
              fillColor: _selected ? theme.tertiary : theme.accent3,
              icon: icon,
              onPressed: () => _onPressed(context),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
