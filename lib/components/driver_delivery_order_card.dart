import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/order_list_display_helpers.dart';
import '/backend/order_status_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/google_maps_service.dart';

/// Driver delivery list row with address, date, time, products, and status.
class DriverDeliveryOrderCard extends StatelessWidget {
  const DriverDeliveryOrderCard({
    super.key,
    required this.order,
    required this.items,
    required this.locale,
  });

  final OrdersRecord order;
  final List<OrderItemRecord> items;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final statusLabel = orderListStatusLabel(order);
    final statusColor = orderListStatusColor(order.status);
    final products = orderListProductSummary(items);

    return Material(
      color: Colors.transparent,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.alternate),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      orderListOrderId(order),
                      style: theme.titleMedium.override(
                        font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  _StatusChip(label: statusLabel, color: statusColor),
                ],
              ),
              if (order.clientName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  order.clientName,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                child: InkWell(
                  onTap: order.address.isEmpty
                      ? null
                      : () => GoogleMapsService.openDirections(order.address),
                  child: Text(
                    orderListAddress(order),
                    style: theme.bodySmall.override(
                      font: GoogleFonts.inter(),
                      color: order.address.isEmpty ? theme.secondaryText : theme.primary,
                      decoration: order.address.isEmpty
                          ? TextDecoration.none
                          : TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                child: Text(
                  orderListDeliveryDateOnly(order, locale: locale),
                  style: theme.bodySmall,
                ),
              ),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'Time',
                child: Text(
                  orderListDeliveryTimeSlot(order),
                  style: theme.bodySmall,
                ),
              ),
              _InfoRow(
                icon: Icons.local_florist_outlined,
                label: 'Products',
                crossAxisAlignment: CrossAxisAlignment.start,
                child: Text(
                  products,
                  style: GoogleFonts.inter(
                    fontSize: theme.bodySmall.fontSize,
                    color: theme.bodySmall.color,
                    height: 1.4,
                  ),
                ),
              ),
              StreamBuilder<OrdersRecord>(
                  stream: OrdersRecord.getDocument(order.reference),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final liveOrder = snapshot.data!;
                    final label = _actionButtonLabel(liveOrder.status);
                    if (label.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FFButtonWidget(
                        onPressed: () async {
                          final nextStatus = _nextDriverStatus(liveOrder.status);
                          if (nextStatus == null) {
                            return;
                          }
                          await liveOrder.reference.update(
                            createOrderStatusUpdateData(nextStatus),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_actionSuccessMessage(nextStatus)),
                              backgroundColor: theme.secondary,
                            ),
                          );
                        },
                        text: label,
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 40,
                          color: theme.success,
                          textStyle: theme.titleSmall.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                            ),
                            color: theme.primaryBackground,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  OrderStatus? _nextDriverStatus(OrderStatus? current) {
    switch (current) {
      case OrderStatus.ready_to_delivery:
        return OrderStatus.out_of_delivery;
      case OrderStatus.out_of_delivery:
        return OrderStatus.completed;
      default:
        return null;
    }
  }

  String _actionButtonLabel(OrderStatus? status) {
    switch (status) {
      case OrderStatus.ready_to_delivery:
        return 'Out for Delivery';
      case OrderStatus.out_of_delivery:
        return 'Mark as Delivered';
      default:
        return '';
    }
  }

  String _actionSuccessMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.out_of_delivery:
        return 'Marked out for delivery';
      case OrderStatus.completed:
        return 'Delivery completed';
      default:
        return 'Status updated';
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: FlutterFlowTheme.of(context).primaryText,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Icon(icon, size: 16, color: theme.secondaryText),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.labelSmall.override(
                color: theme.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
