import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/order_item_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/components/order_detail_item_tile.dart';
import '/components/receipt_order_item_list.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Order summary row: image, name, remark, unit price, and +/- qty controls.
class OrderSummaryItemTile extends StatelessWidget {
  const OrderSummaryItemTile({
    super.key,
    required this.item,
    required this.orderRef,
  });

  final OrderItemRecord item;
  final DocumentReference orderRef;

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final name = item.name.isNotEmpty ? item.name : 'Item';
    final remark = ReceiptOrderItemRow.displayRemark(item.remark);

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onLongPress: () async {
        await deleteOrderItemLine(
          item: item,
          orderRef: orderRef,
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: theme.alternate,
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
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
                      style: GoogleFonts.interTight(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                        height: 1.25,
                      ),
                    ),
                    if (remark.isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        remark,
                        style: GoogleFonts.inter(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w400,
                          color: theme.secondaryText,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6.0),
                    Text(
                      'Unit price: ${_money(item.price)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              _QtyControls(
                item: item,
                orderRef: orderRef,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyControls extends StatelessWidget {
  const _QtyControls({
    required this.item,
    required this.orderRef,
  });

  final OrderItemRecord item;
  final DocumentReference orderRef;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.qty >= 1)
          FlutterFlowIconButton(
            borderRadius: 16.0,
            buttonSize: 32.0,
            fillColor: theme.alternate,
            icon: Icon(
              Icons.remove,
              color: theme.primaryText,
              size: 16.0,
            ),
            onPressed: () async {
              await decreaseOrderItemQuantityOrDelete(
                item: item,
                orderRef: orderRef,
              );
            },
          ),
        Container(
          width: 40.0,
          height: 32.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(
              color: theme.alternate,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            item.qty.toString(),
            style: GoogleFonts.inter(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
        ),
        FlutterFlowIconButton(
          borderRadius: 16.0,
          buttonSize: 32.0,
          fillColor: theme.primary,
          icon: Icon(
            Icons.add,
            color: theme.primaryBackground,
            size: 16.0,
          ),
          onPressed: () async {
            await increaseOrderItemQuantity(
              item: item,
              orderRef: orderRef,
            );
          },
        ),
      ],
    );
  }
}
