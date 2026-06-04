import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/schema/order_item_record.dart';
import '/backend/schema/product_record.dart';
import '/components/receipt_order_item_list.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Order detail card: product rows with image, name, remark, qty, line total.
class OrderDetailItemList extends StatelessWidget {
  const OrderDetailItemList({
    super.key,
    required this.items,
  });

  final List<OrderItemRecord> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No items',
          style: GoogleFonts.inter(
            fontSize: 14.0,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Divider(
              height: 20.0,
              thickness: 1.0,
              color: FlutterFlowTheme.of(context).alternate,
            ),
          OrderDetailItemTile(item: items[i]),
        ],
      ],
    );
  }
}

class OrderDetailItemTile extends StatelessWidget {
  const OrderDetailItemTile({
    super.key,
    required this.item,
  });

  final OrderItemRecord item;

  static String money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final name = item.name.isNotEmpty ? item.name : 'Item';
    final remark = ReceiptOrderItemRow.displayRemark(item.remark);
    final qty = item.qty > 0 ? item.qty : 1;
    final lineTotal = ReceiptOrderItemRow.lineTotal(item);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductThumb(productRef: item.productRef, theme: theme),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                  height: 1.3,
                ),
              ),
              if (remark.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                Text(
                  remark,
                  style: GoogleFonts.inter(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                    color: theme.secondaryText,
                    height: 1.25,
                  ),
                ),
              ],
              const SizedBox(height: 6.0),
              Text(
                'Qty: $qty',
                style: GoogleFonts.inter(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12.0),
        Text(
          money(lineTotal),
          style: GoogleFonts.inter(
            fontSize: 15.0,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
      ],
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({
    required this.productRef,
    required this.theme,
  });

  final DocumentReference? productRef;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 56.0,
      height: 56.0,
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.alternate),
      ),
      child: Icon(
        Icons.local_florist_rounded,
        color: theme.primary,
        size: 28.0,
      ),
    );

    if (productRef == null) {
      return placeholder;
    }

    return FutureBuilder<ProductRecord>(
      future: ProductRecord.getDocumentOnce(productRef!),
      builder: (context, snapshot) {
        final url = snapshot.data?.image ?? '';
        if (url.isEmpty) {
          return placeholder;
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 56.0,
            height: 56.0,
            fit: BoxFit.cover,
            placeholder: (_, __) => placeholder,
            errorWidget: (_, __, ___) => placeholder,
          ),
        );
      },
    );
  }
}
