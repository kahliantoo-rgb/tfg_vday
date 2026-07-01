import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/order_list_display_helpers.dart';
import '/backend/order_navigation_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/l10n/tr.dart';

/// Ordered stop list + open-in-maps action for driver delivery pages.
class DriverSuggestedRouteSection extends StatelessWidget {
  const DriverSuggestedRouteSection({
    super.key,
    required this.routeOrders,
    required this.onOpenMaps,
    this.locale,
  });

  final List<OrdersRecord> routeOrders;
  final VoidCallback onOpenMaps;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final stops = routeOrders
        .where((order) => order.address.trim().isNotEmpty)
        .toList();

    if (stops.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: theme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr(context, 'order.driver.suggestedRoute'),
                  style: theme.titleMedium.override(
                    font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < stops.length; i++)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openOrderDetail(context, stops[i].reference),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.primary,
                        child: Text(
                          '${i + 1}',
                          style: theme.labelSmall.override(
                            color: theme.primaryBackground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orderListOrderId(stops[i]),
                              style: theme.bodyMedium.override(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (stops[i].clientName.isNotEmpty)
                              Text(
                                stops[i].clientName,
                                style: theme.bodySmall,
                              ),
                            Text(
                              stops[i].address.trim(),
                              style: theme.bodySmall.override(
                                color: theme.secondaryText,
                              ),
                            ),
                            Text(
                              '${orderListDeliveryDateOnly(stops[i], locale: locale)} · '
                              '${orderListDeliveryTimeSlot(stops[i])}',
                              style: theme.bodySmall.override(
                                color: theme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: theme.secondaryText),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          FFButtonWidget(
            onPressed: onOpenMaps,
            text: tr(context, 'order.driver.openInMaps'),
            icon: const Icon(Icons.map_outlined, size: 20),
            options: FFButtonOptions(
              width: double.infinity,
              height: 44,
              color: theme.primary,
              textStyle: theme.titleSmall.override(
                color: theme.primaryBackground,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
