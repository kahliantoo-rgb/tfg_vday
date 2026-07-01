import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/order_list_display_helpers.dart';
import '/backend/responsive_layout_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';

/// Single order row for [Orderlist1Widget] with the requested columns.
class OrderListItemCard extends StatelessWidget {
  const OrderListItemCard({
    super.key,
    required this.order,
    required this.items,
    required this.locale,
    required this.checked,
    required this.onCheckedChanged,
    required this.onTap,
    required this.driverLabel,
  });

  final OrdersRecord order;
  final List<OrderItemRecord> items;
  final String? locale;
  final bool checked;
  final ValueChanged<bool?> onCheckedChanged;
  final VoidCallback onTap;
  final String driverLabel;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final statusColor = orderListStatusColor(order.status);
    final statusLabel = orderListStatusLabel(context, order);
    final cells = <String>[
      orderListOrderId(order),
      orderListCustomer(order),
      orderListRecipient(order),
      orderListAddress(order),
      orderListDeliveryDate(order, locale: locale),
      orderListPickupDelivery(context, order),
      driverLabel,
      orderListProductSummaryLocalized(context, items),
      statusLabel,
    ];

    return Material(
      color: theme.secondaryBackground,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.alternate, width: 1.0),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(6.0, 6.0, 8.0, 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: checked,
                onChanged: onCheckedChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: theme.primary,
                checkColor: theme.info,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide =
                        constraints.maxWidth >= kOrderListTableBreakpoint;
                    if (wide) {
                      return _WideRow(
                        cells: cells,
                        statusColor: statusColor,
                        theme: theme,
                      );
                    }
                    return _NarrowColumn(
                      cells: cells,
                      statusColor: statusColor,
                      theme: theme,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderListTableHeader extends StatelessWidget {
  const OrderListTableHeader({
    super.key,
    this.selectAllValue,
    this.onSelectAllChanged,
  });

  final bool? selectAllValue;
  final ValueChanged<bool?>? onSelectAllChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final columns = orderListColumnLabels(context);
    return Container(
      color: theme.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.fromLTRB(6.0, 6.0, 8.0, 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            tristate: true,
            value: selectAllValue,
            onChanged: onSelectAllChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            activeColor: theme.primary,
            checkColor: theme.info,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= kOrderListTableBreakpoint;
                if (wide) {
                  return Row(
                    children: [
                      for (var i = 0; i < columns.length; i++)
                        Expanded(
                          flex: _columnFlex(i),
                          child: _headerCell(context, columns[i]),
                        ),
                    ],
                  );
                }
                return Text(
                  columns.join(' · '),
                  style: _headerStyle(context).copyWith(fontSize: 11.0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(BuildContext context) => GoogleFonts.inter(
        fontSize: 12.0,
        fontWeight: FontWeight.w700,
        color: FlutterFlowTheme.of(context).primaryText,
      );

  Widget _headerCell(BuildContext context, String label) => Text(
        label,
        style: _headerStyle(context),
      );
}

int _columnFlex(int index) {
  switch (index) {
    case 0:
      return 3;
    case 1:
    case 2:
      return 2;
    case 3:
      return 3;
    case 4:
      return 2;
    case 5:
      return 1;
    case 6:
      return 2;
    case 7:
      return 4;
    case 8:
      return 2;
    default:
      return 1;
  }
}

class _WideRow extends StatelessWidget {
  const _WideRow({
    required this.cells,
    required this.statusColor,
    required this.theme,
  });

  final List<String> cells;
  final Color statusColor;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: _columnFlex(i),
            child: i == cells.length - 1
                ? _StatusChip(label: cells[i], color: statusColor)
                : _CellText(
                    text: cells[i],
                    bold: i == 0,
                    theme: theme,
                    maxLines: i == 3 ? 2 : 1,
                  ),
          ),
      ],
    );
  }
}

class _NarrowColumn extends StatelessWidget {
  const _NarrowColumn({
    required this.cells,
    required this.statusColor,
    required this.theme,
  });

  final List<String> cells;
  final Color statusColor;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                cells[0],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _StatusChip(label: cells[8], color: statusColor),
          ],
        ),
        const SizedBox(height: 3),
        _compactLine(tr(context, 'order.col.customer'), cells[1]),
        _compactLine(tr(context, 'order.col.recipient'), cells[2]),
        _compactLine(tr(context, 'order.col.address'), cells[3], maxLines: 2),
        _compactLine(tr(context, 'order.col.deliveryDate'), '${cells[4]} · ${cells[5]}'),
        _compactLine(tr(context, 'order.col.driver'), cells[6]),
        _compactLine(tr(context, 'order.col.product'), cells[7], maxLines: 2),
      ],
    );
  }

  Widget _compactLine(String label, String value, {int maxLines = 1}) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: RichText(
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 11.5,
            height: 1.25,
            color: theme.primaryText,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.secondaryText,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  const _CellText({
    required this.text,
    required this.theme,
    this.bold = false,
    this.maxLines = 1,
  });

  final String text;
  final FlutterFlowTheme theme;
  final bool bold;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: bold ? 14.0 : 13.0,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: theme.primaryText,
        height: 1.35,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          color: FlutterFlowTheme.of(context).primaryText,
        ),
      ),
    );
  }
}
