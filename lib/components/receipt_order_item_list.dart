import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/schema/order_item_record.dart';
import '/backend/order_item_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Line-item block for retail / delivery receipt previews.
class ReceiptOrderItemList extends StatelessWidget {
  const ReceiptOrderItemList({
    super.key,
    required this.items,
    this.textColor,
    this.showPrices = true,
  });

  final List<OrderItemRecord> items;
  final Color? textColor;
  final bool showPrices;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final ink = textColor ?? theme.primaryText;
    final visibleItems = activeOrderItems(items);

    if (visibleItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          'No items',
          style: GoogleFonts.inter(
            fontSize: 12.0,
            color: ink.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visibleItems.length; i++) ...[
          if (i > 0)
            Divider(
              height: 12.0,
              thickness: 0.5,
              color: ink.withValues(alpha: 0.15),
            ),
          ReceiptOrderItemRow(
            item: visibleItems[i],
            textColor: ink,
            showPrices: showPrices,
          ),
        ],
      ],
    );
  }
}

class ReceiptOrderItemRow extends StatelessWidget {
  const ReceiptOrderItemRow({
    super.key,
    required this.item,
    required this.textColor,
    this.showPrices = true,
  });

  final OrderItemRecord item;
  final Color textColor;
  final bool showPrices;

  static String displayRemark(String remark) {
    final trimmed = remark.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final upper = trimmed.toUpperCase();
    if (upper == 'NA' || upper == 'N/A' || upper == '-') {
      return '';
    }
    return trimmed;
  }

  static double lineTotal(OrderItemRecord item) {
    final qty = item.qty > 0 ? item.qty : 1;
    if (item.subtotal > 0) {
      return item.subtotal;
    }
    return item.price * qty;
  }

  static String money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final name = item.name.isNotEmpty ? item.name : 'Item';
    final qty = item.qty > 0 ? item.qty : 1;
    final total = lineTotal(item);
    final remark = displayRemark(item.remark);
    final unitPrice = item.price > 0 ? item.price : total / qty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPrices)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                money(total),
                style: GoogleFonts.inter(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          )
        else
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 1.3,
            ),
          ),
        const SizedBox(height: 3.0),
        Text(
          showPrices ? 'Qty $qty · @ ${money(unitPrice)}' : 'Qty $qty',
          style: GoogleFonts.inter(
            fontSize: 11.0,
            fontWeight: FontWeight.w400,
            color: textColor.withValues(alpha: 0.72),
            height: 1.25,
          ),
        ),
        if (remark.isNotEmpty) ...[
          const SizedBox(height: 2.0),
          Text(
            'Remark: $remark',
            style: GoogleFonts.inter(
              fontSize: 11.0,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: textColor.withValues(alpha: 0.72),
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}
