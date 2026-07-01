import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/tenant_context.dart';
import '/flutter_flow/upload_data.dart';

String invoicePaymentProofStoragePath(
  String companyId,
  String invoiceId,
  String filename,
) {
  final safeCompanyId =
      companyId.isEmpty ? 'default' : companyId.replaceAll('/', '_');
  final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  return 'invoice_payment_proof_images/$safeCompanyId/$invoiceId/$safeName';
}

Future<String?> pickAndUploadInvoicePaymentProof({
  required BuildContext context,
  required String invoiceId,
  String? companyId,
}) async {
  if (!loggedIn) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upload payment proof.')),
      );
    }
    return null;
  }

  final selectedMedia = await selectMediaWithSourceBottomSheet(
    context: context,
    allowPhoto: true,
  );
  if (selectedMedia == null ||
      selectedMedia.isEmpty ||
      !selectedMedia.every(
        (media) => validateFileFormat(media.storagePath, context),
      )) {
    return null;
  }

  final media = selectedMedia.first;
  final filename = media.storagePath.split('/').last;
  final resolvedCompanyId =
      companyId ?? TenantContext.instance.writeCompanyId;
  final storagePath = invoicePaymentProofStoragePath(
    resolvedCompanyId,
    invoiceId,
    filename,
  );
  final uploadResult = await uploadDataWithResult(
    storagePath,
    media.bytes,
  );
  if (!uploadResult.isSuccess) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            storageUploadFailureMessage(
              uploadResult,
              storagePath: storagePath,
            ),
          ),
        ),
      );
    }
    return null;
  }

  final downloadUrl = uploadResult.downloadUrl!;
  if (!isValidFirebaseStorageDownloadUrl(downloadUrl)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload returned an invalid photo URL. Try again.'),
        ),
      );
    }
    return null;
  }
  return downloadUrl;
}

class MarkInvoicesPaidDialogResult {
  const MarkInvoicesPaidDialogResult({this.paymentProofUrl});

  final String? paymentProofUrl;
}

Future<MarkInvoicesPaidDialogResult?> showMarkInvoicesPaidDialog(
  BuildContext context, {
  required int invoiceCount,
  required String storageInvoiceId,
}) {
  return showDialog<MarkInvoicesPaidDialogResult>(
    context: context,
    builder: (dialogContext) => _MarkInvoicesPaidDialog(
      invoiceCount: invoiceCount,
      storageInvoiceId: storageInvoiceId,
    ),
  );
}

class _MarkInvoicesPaidDialog extends StatefulWidget {
  const _MarkInvoicesPaidDialog({
    required this.invoiceCount,
    required this.storageInvoiceId,
  });

  final int invoiceCount;
  final String storageInvoiceId;

  @override
  State<_MarkInvoicesPaidDialog> createState() => _MarkInvoicesPaidDialogState();
}

class _MarkInvoicesPaidDialogState extends State<_MarkInvoicesPaidDialog> {
  String? _paymentProofUrl;
  bool _uploading = false;

  Future<void> _uploadProof() async {
    setState(() => _uploading = true);
    try {
      final url = await pickAndUploadInvoicePaymentProof(
        context: context,
        invoiceId: widget.storageInvoiceId,
      );
      if (!mounted || url == null) {
        return;
      }
      setState(() => _paymentProofUrl = url);
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proofUrl = _paymentProofUrl?.trim() ?? '';

    return AlertDialog(
      title: const Text('Mark as paid?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mark ${widget.invoiceCount} invoice(s) as paid and update linked '
              'orders to payment done?',
            ),
            const SizedBox(height: 16),
            Text(
              'Payment proof (optional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload bank transfer screenshot or receipt. '
              'You can mark paid without a photo.',
              style: TextStyle(fontSize: 13),
            ),
            if (proofUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    proofUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('Could not preview photo.'),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _uploadProof,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      proofUrl.isEmpty
                          ? Icons.photo_camera_outlined
                          : Icons.refresh,
                    ),
              label: Text(
                proofUrl.isEmpty ? 'Upload payment proof' : 'Replace photo',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            MarkInvoicesPaidDialogResult(paymentProofUrl: _paymentProofUrl),
          ),
          child: const Text('Mark paid'),
        ),
      ],
    );
  }
}
