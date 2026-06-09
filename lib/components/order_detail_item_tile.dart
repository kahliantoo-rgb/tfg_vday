import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/product_edit_helpers.dart';
import '/backend/order_item_helpers.dart';
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
    final visibleItems = activeOrderItems(items);

    if (visibleItems.isEmpty) {
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
        for (var i = 0; i < visibleItems.length; i++) ...[
          if (i > 0)
            Divider(
              height: 20.0,
              thickness: 1.0,
              color: FlutterFlowTheme.of(context).alternate,
            ),
          OrderDetailItemTile(item: visibleItems[i]),
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
        OrderItemProductThumb(
          productRef: item.productRef,
          imageUrl: item.image,
          title: name,
          theme: theme,
        ),
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

class OrderItemProductThumb extends StatelessWidget {
  const OrderItemProductThumb({
    required this.productRef,
    required this.imageUrl,
    required this.theme,
    this.title,
  });

  final DocumentReference? productRef;
  final String imageUrl;
  final FlutterFlowTheme theme;
  final String? title;

  String _pickImageUrl({required String itemImage, String productImage = ''}) {
    if (isUsableImageUrl(itemImage)) {
      return itemImage;
    }
    if (isUsableImageUrl(productImage)) {
      return productImage;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (productRef != null) {
      return StreamBuilder<ProductRecord>(
        stream: ProductRecord.getDocument(productRef!),
        builder: (context, snapshot) {
          final productImage = snapshot.hasData
              ? productImageFromRecord(snapshot.data!)
              : '';
          return buildZoomableProductImage(
            context: context,
            imageUrl: _pickImageUrl(
              itemImage: imageUrl,
              productImage: productImage,
            ),
            productRef: productRef,
            title: title,
            width: 56.0,
            height: 56.0,
            placeholderIcon: Icons.local_florist_rounded,
          );
        },
      );
    }

    return buildZoomableProductImage(
      context: context,
      imageUrl: _pickImageUrl(itemImage: imageUrl),
      productRef: productRef,
      title: title,
      width: 56.0,
      height: 56.0,
      placeholderIcon: Icons.local_florist_rounded,
    );
  }
}
