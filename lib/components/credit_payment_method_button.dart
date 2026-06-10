import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/backend.dart';
import '/backend/payment_method_helpers.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class CreditPaymentMethodButton extends StatelessWidget {
  const CreditPaymentMethodButton({
    super.key,
    required this.orderRef,
    required this.currentPaymentType,
    this.width = 80,
    this.height = 75.1,
    this.useBodySmall = false,
  });

  final DocumentReference orderRef;
  final String? currentPaymentType;
  final double width;
  final double height;
  final bool useBodySmall;

  Future<void> _onPressed(BuildContext context) async {
    final paymentType = await showCreditTermPickerDialog(context);
    if (paymentType == null || !context.mounted) {
      return;
    }
    await orderRef.update(createOrdersRecordData(paymentType: paymentType));
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final selected = isCreditPaymentType(currentPaymentType);
    final label = selected
        ? creditTermShortLabel(currentPaymentType!)
        : 'Credit';
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
              fillColor: selected ? theme.tertiary : theme.accent3,
              icon: Icon(
                Icons.receipt_long_outlined,
                color: theme.info,
                size: useBodySmall ? 24.0 : 22.0,
              ),
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
