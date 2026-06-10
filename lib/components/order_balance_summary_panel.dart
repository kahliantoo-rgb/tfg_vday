import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/cash_payment_helpers.dart';
import '/backend/order_balance_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class OrderBalanceSummaryPanel extends StatelessWidget {
  const OrderBalanceSummaryPanel({
    super.key,
    required this.order,
    required this.saleTotal,
  });

  final OrdersRecord order;
  final double saleTotal;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final amountPaid = readOrderAmountPaid(order);
    final balanceDue = order.balanceDue > 0
        ? order.balanceDue
        : calculateBalanceDue(saleTotal: saleTotal, amountPaid: amountPaid);

    if (amountPaid <= 0.005 && balanceDue <= 0.005) {
      return const SizedBox.shrink();
    }

    TextStyle labelStyle = theme.bodyMedium.override(
      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
    );
    TextStyle valueStyle = theme.bodyMedium.override(
      font: GoogleFonts.inter(fontWeight: FontWeight.w700),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount paid', style: labelStyle),
              Text(formatCashMoney(amountPaid), style: valueStyle),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance due',
                style: labelStyle.override(
                  font: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: theme.error,
                  ),
                ),
              ),
              Text(
                formatCashMoney(balanceDue),
                style: valueStyle.override(
                  font: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: theme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
