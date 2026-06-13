import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/backend/order_list_filter_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class OrderDeliveryProofSection extends StatelessWidget {
  const OrderDeliveryProofSection({
    super.key,
    required this.order,
  });

  final OrdersRecord order;

  bool get _shouldShow {
    if (order.deliveryProofUrl.trim().isNotEmpty) {
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

  void _openFullscreen(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load delivery proof photo.'),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) {
      return const SizedBox.shrink();
    }

    final theme = FlutterFlowTheme.of(context);
    final proofUrl = order.deliveryProofUrl.trim();
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
            if (proofUrl.isEmpty)
              Text(
                'No delivery proof uploaded yet.',
                style: theme.bodyMedium.override(color: theme.secondaryText),
              )
            else ...[
              InkWell(
                onTap: () => _openFullscreen(context, proofUrl),
                borderRadius: BorderRadius.circular(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      proofUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.alternate,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: theme.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
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
