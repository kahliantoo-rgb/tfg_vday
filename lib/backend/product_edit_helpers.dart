import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/firebase_storage/storage.dart';
import '/backend/schema/product_record.dart';
import '/flutter_flow/upload_data.dart';

/// Storage path for a product image upload.
String productImageStoragePath(String productId, String filename) {
  final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  return 'product_images/$productId/$safeName';
}

bool isUsableImageUrl(String? url) {
  if (url == null || url.isEmpty) {
    return false;
  }
  return url.startsWith('http') || url.startsWith('gs://');
}

/// Picks an image, uploads to Storage, and writes [image] on the product doc.
Future<String?> pickAndUploadProductImage({
  required BuildContext context,
  required DocumentReference productRef,
}) async {
  final selectedMedia = await selectMediaWithSourceBottomSheet(
    context: context,
    allowPhoto: true,
  );
  if (selectedMedia == null ||
      selectedMedia.isEmpty ||
      !selectedMedia.every(
        (m) => validateFileFormat(m.storagePath, context),
      )) {
    return null;
  }

  final media = selectedMedia.first;
  final filename = media.storagePath.split('/').last;
  final path = productImageStoragePath(productRef.id, filename);
  final downloadUrl = await uploadData(path, media.bytes);
  if (downloadUrl == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed')),
      );
    }
    return null;
  }

  await productRef.update(createProductRecordData(image: downloadUrl));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo updated')),
    );
  }
  return downloadUrl;
}

Future<void> updateProductPrice(
  DocumentReference productRef,
  double? price,
) async {
  await productRef.update(createProductRecordData(price: price));
}

Future<void> updateProductIsActive(
  DocumentReference productRef,
  bool isActive,
) async {
  await productRef.update(createProductRecordData(isActive: isActive));
}
