import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/customer_invoice_helpers.dart';
import '/backend/order_discount_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/tr.dart';

/// Shared % / SGD discount control for Retail and Delivery/Pick Up payment pages.
/// Editable only when [canEdit] is true (admin). Otherwise shows a read-only
/// summary when a discount is already on the order.
class OrderDiscountPanel extends StatelessWidget {
  const OrderDiscountPanel({
    super.key,
    required this.discountType,
    required this.discountController,
    required this.remarkController,
    required this.totals,
    required this.onTypeChanged,
    required this.onValueChanged,
    this.canEdit = false,
    this.existingRemark = '',
  });

  final CustomerInvoiceDiscountType discountType;
  final TextEditingController discountController;
  final TextEditingController remarkController;
  final OrderPayableTotals totals;
  final ValueChanged<CustomerInvoiceDiscountType> onTypeChanged;
  final VoidCallback onValueChanged;
  final bool canEdit;
  final String existingRemark;

  String _money(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    if (!canEdit && totals.discount <= 0.005) {
      return const SizedBox.shrink();
    }

    final theme = FlutterFlowTheme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(context, 'pos.discount.title'),
              style: theme.titleSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              ),
            ),
            if (canEdit) ...[
              const SizedBox(height: 8),
              SegmentedButton<CustomerInvoiceDiscountType>(
                segments: const [
                  ButtonSegment(
                    value: CustomerInvoiceDiscountType.percent,
                    label: Text('%'),
                  ),
                  ButtonSegment(
                    value: CustomerInvoiceDiscountType.amount,
                    label: Text('SGD'),
                  ),
                ],
                selected: {discountType},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  onTypeChanged(selection.first);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: discountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (_) => onValueChanged(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: discountType == CustomerInvoiceDiscountType.percent
                      ? tr(context, 'pos.discount.hintPercent')
                      : tr(context, 'pos.discount.hintAmount'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: remarkController,
                maxLines: 2,
                onChanged: (_) => onValueChanged(),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: tr(context, 'pos.discount.remark'),
                  hintText: tr(context, 'pos.discount.remarkHint'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ] else if (existingRemark.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${tr(context, 'pos.discount.remark')}: ${existingRemark.trim()}',
                style: theme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            _row(
              theme,
              tr(context, 'pos.discount.subtotal'),
              _money(totals.subtotal),
            ),
            const SizedBox(height: 6),
            _row(
              theme,
              tr(
                context,
                'pos.discount.line',
                params: {'label': totals.discountLabel},
              ),
              totals.discount > 0
                  ? '-${_money(totals.discount)}'
                  : _money(0),
            ),
            const Divider(height: 20),
            _row(
              theme,
              tr(context, 'pos.discount.payable'),
              _money(totals.total),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    FlutterFlowTheme theme,
    String label,
    String value, {
    bool bold = false,
  }) {
    final weight = bold ? FontWeight.w700 : FontWeight.w500;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.bodyMedium.override(
              font: GoogleFonts.inter(fontWeight: weight),
            ),
          ),
        ),
        Text(
          value,
          style: theme.bodyMedium.override(
            font: GoogleFonts.inter(fontWeight: weight),
          ),
        ),
      ],
    );
  }
}
