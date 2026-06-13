import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/backend/driver_delivery_proof_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class DriverDeliveryProofPanel extends StatefulWidget {
  const DriverDeliveryProofPanel({
    super.key,
    required this.order,
  });

  final OrdersRecord order;

  @override
  State<DriverDeliveryProofPanel> createState() =>
      _DriverDeliveryProofPanelState();
}

class _DriverDeliveryProofPanelState extends State<DriverDeliveryProofPanel> {
  bool _uploading = false;

  Future<void> _upload(OrdersRecord order) async {
    setState(() => _uploading = true);
    try {
      await uploadOrderDeliveryProof(context: context, order: order);
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrdersRecord>(
      stream: OrdersRecord.getDocument(widget.order.reference),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final order = snapshot.data!;
        if (!orderAllowsDeliveryProofUpload(order.status)) {
          return const SizedBox.shrink();
        }

        final theme = FlutterFlowTheme.of(context);
        final proofUrl = order.deliveryProofUrl.trim();
        final uploadedAt = order.deliveryProofAt;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(8),
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
                if (proofUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        proofUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.alternate,
                          alignment: Alignment.center,
                          child: Icon(Icons.broken_image_outlined,
                              color: theme.secondaryText),
                        ),
                      ),
                    ),
                  ),
                  if (uploadedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Uploaded ${DateFormat('d MMM yyyy, HH:mm').format(uploadedAt.toLocal())}',
                        style: theme.bodySmall.override(
                          color: theme.secondaryText,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 10),
                FFButtonWidget(
                  onPressed: _uploading ? null : () => _upload(order),
                  text: proofUrl.isEmpty
                      ? 'Upload delivery proof'
                      : 'Replace photo',
                  icon: _uploading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primaryBackground,
                          ),
                        )
                      : Icon(
                          Icons.photo_camera_outlined,
                          color: theme.primaryBackground,
                          size: 20,
                        ),
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 40,
                    color: theme.secondary,
                    textStyle: theme.titleSmall.override(
                      font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                      color: theme.primaryBackground,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
