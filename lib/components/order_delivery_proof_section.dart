import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/backend/driver_delivery_proof_helpers.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Product selection grid card image slot (`productselection_copy`).
const _kProductSelectImageWidth = 152.0;
const _kProductSelectImageHeight = 112.0;

class OrderDeliveryProofSection extends StatelessWidget {
  const OrderDeliveryProofSection({
    super.key,
    required this.order,
  });

  final OrdersRecord order;

  bool get _shouldShow {
    if (resolvedDeliveryProofUrls(order).isNotEmpty) {
      return true;
    }
    if (isRetailOrderRecord(order)) {
      return false;
    }
    if (order.hasAssignedDriver()) {
      return true;
    }
    return order.status == OrderStatus.out_of_delivery ||
        order.status == OrderStatus.completed;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) {
      return const SizedBox.shrink();
    }

    final theme = FlutterFlowTheme.of(context);
    final proofUrls = resolvedDeliveryProofUrls(order);
    final uploadedAt = order.deliveryProofAt;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Delivery proof',
              style: theme.titleSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '送达证明',
              style: theme.labelSmall.override(color: theme.secondaryText),
            ),
            const SizedBox(height: 10),
            if (proofUrls.isEmpty)
              Text(
                'No delivery proof uploaded yet.',
                style: theme.bodyMedium.override(color: theme.secondaryText),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final proofUrl in proofUrls)
                    Container(
                      width: _kProductSelectImageWidth,
                      height: _kProductSelectImageHeight,
                      decoration: BoxDecoration(
                        color: theme.alternate.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: buildZoomableProductImage(
                        context: context,
                        imageUrl: proofUrl,
                        title: 'Delivery proof',
                        width: _kProductSelectImageWidth,
                        height: _kProductSelectImageHeight,
                        fit: BoxFit.contain,
                        placeholderIcon: Icons.photo_camera_outlined,
                      ),
                    ),
                ],
              ),
              if (uploadedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Uploaded ${DateFormat('d MMM yyyy, HH:mm').format(uploadedAt.toLocal())}',
                    style: theme.bodySmall.override(color: theme.secondaryText),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tap photo to enlarge',
                  style: theme.labelSmall.override(color: theme.secondaryText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
