import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/tenant_context.dart';
import '/flutter_flow/upload_data.dart';

String customerBroadcastImageStoragePath(String companyId, String filename) {
  final safeCompanyId =
      companyId.isEmpty ? 'default' : companyId.replaceAll('/', '_');
  final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  return 'customer_broadcast_images/$safeCompanyId/$safeName';
}

Future<String?> pickAndUploadCustomerBroadcastImage({
  required BuildContext context,
}) async {
  if (!loggedIn) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upload a photo.')),
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
  final filename =
      '${DateTime.now().millisecondsSinceEpoch}_${media.storagePath.split('/').last}';
  final uploadResult = await uploadDataWithResult(
    customerBroadcastImageStoragePath(
      TenantContext.instance.writeCompanyId,
      filename,
    ),
    media.bytes,
  );
  if (!uploadResult.isSuccess) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(storageUploadFailureMessage(uploadResult))),
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
