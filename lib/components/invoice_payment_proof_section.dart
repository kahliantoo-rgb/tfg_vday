import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/backend/invoice_list_helpers.dart';
import '/backend/schema/invoices_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class InvoicePaymentProofSection extends StatelessWidget {
  const InvoicePaymentProofSection({
    super.key,
    required this.invoice,
  });

  final InvoicesRecord invoice;

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
              child: Text('Could not load payment proof photo.'),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (invoice.status != InvoiceStatus.paid) {
      return const SizedBox.shrink();
    }

    final theme = FlutterFlowTheme.of(context);
    final proofUrl = invoice.paymentProofUrl.trim();
    final uploadedAt = invoice.paymentProofAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Payment proof',
              style: theme.titleMedium.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '付款证明',
              style: theme.labelSmall.override(color: theme.secondaryText),
            ),
            const SizedBox(height: 10),
            if (proofUrl.isEmpty)
              Text(
                'No payment proof uploaded.',
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
