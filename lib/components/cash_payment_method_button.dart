import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/cash_payment_helpers.dart';
import '/backend/order_balance_helpers.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class CashPaymentMethodButton extends StatelessWidget {
  const CashPaymentMethodButton({
    super.key,
    required this.orderRef,
    required this.currentPaymentType,
    this.saleTotal,
    this.onFullyPaid,
    this.width = 80,
    this.height = 75.1,
    this.useBodySmall = false,
  });

  final DocumentReference orderRef;
  final String? currentPaymentType;
  final double? saleTotal;
  final Future<void> Function(PaymentApplicationResult applied)? onFullyPaid;
  final double width;
  final double height;
  final bool useBodySmall;

  Future<void> _onPressed(BuildContext context) async {
    await handleCashPaymentSelection(
      context,
      orderRef: orderRef,
      saleTotal: saleTotal,
      onFullyPaid: onFullyPaid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final selected = currentPaymentType == 'Cash';
    final textStyle = (useBodySmall ? theme.bodySmall : theme.bodyMedium)
        .override(
      font: GoogleFonts.inter(
        fontWeight: useBodySmall ? FontWeight.w500 : theme.bodyMedium.fontWeight,
        fontStyle: useBodySmall
            ? theme.bodySmall.fontStyle
            : theme.bodyMedium.fontStyle,
      ),
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
              buttonSize: useBodySmall ? 35.0 : 35.0,
              fillColor: selected ? theme.tertiary : theme.accent3,
              icon: FaIcon(
                FontAwesomeIcons.moneyBillWaveAlt,
                color: theme.info,
                size: 22.0,
              ),
              onPressed: () => _onPressed(context),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
              child: Text('Cash', style: textStyle),
            ),
          ],
        ),
      ),
    );
  }
}
