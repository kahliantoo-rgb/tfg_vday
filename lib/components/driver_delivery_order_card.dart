import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/components/driver_delivery_proof_panel.dart';
import '/backend/order_navigation_helpers.dart';
import '/backend/driver_delivery_action_helpers.dart';
import '/backend/order_list_display_helpers.dart';
import '/backend/order_status_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/google_maps_service.dart';
import '/l10n/locale_text.dart';

/// Driver delivery list row with address, date, time, products, and status.
class DriverDeliveryOrderCard extends StatelessWidget {
  const DriverDeliveryOrderCard({
    super.key,
    required this.order,
    required this.items,
    required this.locale,
    this.showDriverActions = true,
    this.showOrderDetailNav = false,
    this.onTap,
  });

  final OrdersRecord order;
  final List<OrderItemRecord> items;
  final String? locale;
  final bool showDriverActions;
  final bool showOrderDetailNav;
  final VoidCallback? onTap;

  bool get _opensOrderDetail => showOrderDetailNav || onTap != null;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final statusLabel = orderListStatusLabel(context, order);
    final statusColor = orderListStatusColor(order.status);
    final products = orderListProductSummary(items);

    final cardBody = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderListOrderId(order),
                      style: theme.titleMedium.override(
                        font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_opensOrderDetail)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          loc(
                            context,
                            en: 'Tap for order details',
                            zh: '点击查看订单详情',
                            ms: 'Ketik untuk butiran pesanan',
                          ),
                          style: theme.labelSmall.override(
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(label: statusLabel, color: statusColor),
                  if (_opensOrderDetail) ...[
                    const SizedBox(height: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.primary,
                      size: 28,
                    ),
                  ],
                ],
              ),
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
            label: loc(context, en: 'Address', zh: '地址', ms: 'Alamat'),
            child: InkWell(
              onTap: order.address.isEmpty
                  ? null
                  : () => GoogleMapsService.openDirections(order.address),
              child: Text(
                orderListAddress(order),
                style: theme.bodySmall.override(
                  font: GoogleFonts.inter(),
                  color:
                      order.address.isEmpty ? theme.secondaryText : theme.primary,
                  decoration: order.address.isEmpty
                      ? TextDecoration.none
                      : TextDecoration.underline,
                ),
              ),
            ),
          ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: loc(context, en: 'Date', zh: '日期', ms: 'Tarikh'),
            child: Text(
              orderListDeliveryDateOnly(order, locale: locale),
              style: theme.bodySmall,
            ),
          ),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: loc(context, en: 'Time', zh: '时间', ms: 'Masa'),
            child: Text(
              orderListDeliveryTimeSlot(order),
              style: theme.bodySmall,
            ),
          ),
          _InfoRow(
            icon: Icons.local_florist_outlined,
            label: loc(context, en: 'Products', zh: '产品', ms: 'Produk'),
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
          if (showDriverActions) DriverDeliveryProofPanel(order: order),
          if (showDriverActions)
            StreamBuilder<OrdersRecord>(
              stream: OrdersRecord.getDocument(order.reference),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final liveOrder = snapshot.data!;
                final label = _actionButtonLabel(context, liveOrder.status);
                if (label.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FFButtonWidget(
                      onPressed: () async {
                        if (driverCanRecordDelivery(liveOrder.status)) {
                          openPartialDelivery(
                            context,
                            liveOrder.reference,
                          );
                          return;
                        }
                        if (!driverCanStartOutForDelivery(liveOrder.status)) {
                          return;
                        }
                        await updateOrderStatus(
                          liveOrder.reference,
                          OrderStatus.out_of_delivery,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _actionSuccessMessage(
                                context,
                                OrderStatus.out_of_delivery,
                              ),
                            ),
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
                }
                if (driverShowsWaitingForReadyHint(liveOrder.status)) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.accent1.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.accent1.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.hourglass_top_rounded,
                            size: 18,
                            color: theme.secondaryText,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc(
                                context,
                                en: 'Waiting for Ready to Ship — start delivery once marked ready',
                                zh: '等待出货，标记为可出货后可开始派送',
                                ms: 'Menunggu sedia dihantar — mula penghantaran selepas ditandakan sedia',
                              ),
                              style: theme.bodySmall.override(
                                font: GoogleFonts.inter(),
                                color: theme.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          if (_opensOrderDetail && !showDriverActions)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FFButtonWidget(
                onPressed: onTap,
                text: loc(
                  context,
                  en: 'View order details',
                  zh: '查看订单详情',
                  ms: 'Lihat butiran pesanan',
                ),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.primaryBackground,
                  size: 20,
                ),
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 40,
                  color: theme.primary,
                  textStyle: theme.titleSmall.override(
                    font: GoogleFonts.interTight(
                      fontWeight: FontWeight.w600,
                    ),
                    color: theme.primaryBackground,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );

    if (!_opensOrderDetail) {
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
          child: cardBody,
        ),
      );
    }

    return Material(
      color: theme.secondaryBackground,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: theme.alternate),
            borderRadius: BorderRadius.circular(12),
          ),
          child: cardBody,
        ),
      ),
    );
  }

  String _actionButtonLabel(BuildContext context, OrderStatus? status) {
    if (driverCanStartOutForDelivery(status)) {
      return loc(
        context,
        en: 'Out for Delivery',
        zh: '开始派送',
        ms: 'Keluar untuk Penghantaran',
      );
    }
    if (driverCanRecordDelivery(status)) {
      return loc(
        context,
        en: 'Record delivery',
        zh: '记录送达',
        ms: 'Rekod Penghantaran',
      );
    }
    return '';
  }

  String _actionSuccessMessage(BuildContext context, OrderStatus status) {
    switch (status) {
      case OrderStatus.out_of_delivery:
        return loc(
          context,
          en: 'Marked out for delivery',
          zh: '已标记为派送中',
          ms: 'Ditandakan dalam penghantaran',
        );
      case OrderStatus.completed:
        return loc(
          context,
          en: 'Delivery completed',
          zh: '送达完成',
          ms: 'Penghantaran selesai',
        );
      default:
        return loc(
          context,
          en: 'Status updated',
          zh: '状态已更新',
          ms: 'Status dikemas kini',
        );
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
