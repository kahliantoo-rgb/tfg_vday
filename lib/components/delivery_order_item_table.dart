import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/order_item_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/components/receipt_order_item_list.dart';

/// A4 delivery order table: Item Name | Remark | Qty with fixed column widths.
class DeliveryOrderItemTable extends StatelessWidget {
  const DeliveryOrderItemTable({
    super.key,
    required this.items,
    this.fontSize = 14.0,
    this.headerFontSize,
  });

  final List<OrderItemRecord> items;
  final double fontSize;
  final double? headerFontSize;

  static const double remarkColumnWidth = 140.0;
  static const double qtyColumnWidth = 56.0;

  TextStyle _headerStyle() => GoogleFonts.inter(
        fontSize: headerFontSize ?? fontSize,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        height: 1.25,
      );

  TextStyle _cellStyle() => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: Colors.black,
        height: 1.35,
      );

  static String remarkText(OrderItemRecord item) {
    final remark = ReceiptOrderItemRow.displayRemark(item.remark);
    return remark.isEmpty ? '-' : remark;
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = activeOrderItems(items);

    if (visibleItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        child: Text('No items', style: _cellStyle()),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FixedColumnWidth(remarkColumnWidth),
        2: FixedColumnWidth(qtyColumnWidth),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: Colors.black, width: 1.0),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
          children: [
            _headerCell('Item Name'),
            _headerCell('Remark', align: TextAlign.center),
            _headerCell('Qty', align: TextAlign.right),
          ],
        ),
        for (final item in visibleItems)
          TableRow(
            children: [
              _bodyCell(item.name.isNotEmpty ? item.name : 'Item'),
              _bodyCell(remarkText(item), align: TextAlign.center),
              _bodyCell(
                '${item.qty}',
                align: TextAlign.right,
              ),
            ],
          ),
      ],
    );
  }

  Widget _headerCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Text(
        text,
        textAlign: align,
        style: _headerStyle(),
      ),
    );
  }

  Widget _bodyCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Text(
        text,
        textAlign: align,
        style: _cellStyle(),
      ),
    );
  }
}
