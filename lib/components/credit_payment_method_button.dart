import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/backend.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/material_cost_snapshot_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class CreditPaymentMethodButton extends StatelessWidget {
  const CreditPaymentMethodButton({
    super.key,
    required this.orderRef,
    required this.currentPaymentType,
    this.pendingSelection,
    this.onSelectionChanged,
    this.width = 80,
    this.height = 75.1,
    this.useBodySmall = false,
  });

  final DocumentReference orderRef;
  final String? currentPaymentType;
  final PendingOrderPaymentSelection? pendingSelection;
  final ValueChanged<PendingOrderPaymentSelection>? onSelectionChanged;
  final double width;
  final double height;
  final bool useBodySmall;

  bool get _selectionOnly => onSelectionChanged != null;

  bool get _selected {
    final pendingType = pendingSelection?.paymentType;
    if (pendingType != null && isCreditPaymentType(pendingType)) {
      return true;
    }
    return !_selectionOnly && isCreditPaymentType(currentPaymentType);
  }

  String get _label {
    if (pendingSelection != null &&
        isCreditPaymentType(pendingSelection!.paymentType)) {
      return creditTermShortLabel(pendingSelection!.paymentType);
    }
    if (_selected && isCreditPaymentType(currentPaymentType)) {
      return creditTermShortLabel(currentPaymentType!);
    }
    return 'Credit';
  }

  Future<void> _onPressed(BuildContext context) async {
    final paymentType = await showCreditTermPickerDialog(context);
    if (paymentType == null || !context.mounted) {
      return;
    }

    if (_selectionOnly) {
      final selection = PendingOrderPaymentSelection(
        paymentType: paymentType,
        amountReceivedThisTime: 0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describePendingOrderPayment(selection))),
      );
      onSelectionChanged!(selection);
      return;
    }

    await orderRef.update(createOrdersRecordData(paymentType: paymentType));
    await ensureOrderMaterialCostSnapshot(orderRef);
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
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: theme.info,
                    size: useBodySmall ? 24.0 : 22.0,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                  child: Text(
                    _label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
