import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/viewer_role_helpers.dart';
import '/auth/role_helpers.dart';
import '/backend/bulk_order_actions_helpers.dart';
import '/backend/order_list_display_helpers.dart';
import '/backend/order_status_display.dart';
import '/backend/order_whatsapp_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';

Future<bool> showBulkUpdateStatusSheet(
  BuildContext context, {
  required List<OrdersRecord> orders,
}) async {
  if (!canUpdateOrderStatus(currentViewerRole())) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(context, 'order.bulk.updateStatusDenied'))),
    );
    return false;
  }
  if (orders.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(context, 'order.bulk.selectFirst'))),
    );
    return false;
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _BulkUpdateStatusSheet(orders: orders),
  );
  return result == true;
}

class _BulkUpdateStatusSheet extends StatefulWidget {
  const _BulkUpdateStatusSheet({required this.orders});

  final List<OrdersRecord> orders;

  @override
  State<_BulkUpdateStatusSheet> createState() => _BulkUpdateStatusSheetState();
}

class _BulkUpdateStatusSheetState extends State<_BulkUpdateStatusSheet> {
  bool _saving = false;

  Future<void> _apply(OrderStatus status) async {
    setState(() => _saving = true);
    try {
      final count = await bulkUpdateOrdersStatus(
        orders: widget.orders,
        status: status,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'order.bulk.statusApplied',
              params: {
                'count': '$count',
                'status': orderStatusDisplayLabel(
                  context,
                  status,
                  isPickup: widget.orders.every(isPickupOrderRecord),
                ),
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'order.bulk.updateStatusFailed', params: {'error': '$e'}),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final allPickup = widget.orders.every(isPickupOrderRecord);
    final statuses = orderStatusUpdateOptions(isPickup: allPickup);

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(context, 'order.bulk.updateStatusTitle'),
                style: theme.titleLarge.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr(
                  context,
                  'order.bulk.selectedCount',
                  params: {'count': '${widget.orders.length}'},
                ),
                style: theme.bodySmall.override(color: theme.secondaryText),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: statuses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final status = statuses[index];
                    final color = orderListStatusColor(status);
                    final label = orderStatusDisplayLabel(
                      context,
                      status,
                      isPickup: allPickup,
                    );
                    return Material(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _saving ? null : () => _apply(status),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                          ),
                        ),
                      ),
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
