import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/firebase_storage/storage.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/upload_data.dart';

enum CustomProductAddOption {
  uploadPhoto,
  add,
}

/// Ask whether to upload a reference photo or add the line item without one.
Future<CustomProductAddOption?> showCustomProductAddOptionDialog(
  BuildContext context,
) {
  return showDialog<CustomProductAddOption>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Custom product'),
      content: const Text('Upload a photo or add without photo?'),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, CustomProductAddOption.uploadPhoto),
          child: const Text('Upload Photo'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, CustomProductAddOption.add),
          child: const Text('Add'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

String customProductImageStoragePath(String orderItemId, String filename) {
  final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  return 'custom_product_images/$orderItemId/$safeName';
}

Future<String?> pickAndUploadCustomProductImage({
  required BuildContext context,
  required String orderItemId,
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
  final path = customProductImageStoragePath(orderItemId, filename);
  final uploadResult = await uploadDataWithResult(path, media.bytes);
  if (!uploadResult.isSuccess && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(storageUploadFailureMessage(uploadResult))),
    );
  }
  return uploadResult.downloadUrl;
}

Future<DocumentReference?> createCustomProductOrderItem({
  required BuildContext context,
  required DocumentReference? orderRef,
  required String name,
  required int qty,
  required double? price,
  required String remark,
  String? imageUrl,
  DocumentReference? itemRef,
}) async {
  if (orderRef == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order reference missing.')),
      );
    }
    return null;
  }
  if (!ensureActiveCompanyForWrite(context)) {
    return null;
  }

  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a custom product name.')),
      );
    }
    return null;
  }

  final ref = itemRef ?? OrderItemRecord.collection.doc();
  final linePrice = price ?? 0;
  await ref.set(
    createTenantOrderItemRecordData(
      orderRef: orderRef,
      name: trimmedName,
      qty: qty,
      price: price,
      subtotal: linePrice * qty,
      remark: remark.trim(),
      sku: 'Customize',
      image: imageUrl,
    ),
  );
  return ref;
}

/// Validates form, shows upload/add dialog, optionally uploads photo, writes item.
Future<bool> submitCustomProductWithPhotoChoice({
  required BuildContext context,
  required DocumentReference? orderRef,
  required String name,
  required int qty,
  required double? price,
  required String remark,
}) async {
  final choice = await showCustomProductAddOptionDialog(context);
  if (choice == null || !context.mounted) {
    return false;
  }

  final itemRef = OrderItemRecord.collection.doc();
  String? imageUrl;
  if (choice == CustomProductAddOption.uploadPhoto) {
    imageUrl = await pickAndUploadCustomProductImage(
      context: context,
      orderItemId: itemRef.id,
    );
    if (imageUrl == null) {
      return false;
    }
    if (!context.mounted) {
      return false;
    }
  }

  final ref = await createCustomProductOrderItem(
    context: context,
    orderRef: orderRef,
    name: name,
    qty: qty,
    price: price,
    remark: remark,
    imageUrl: imageUrl,
    itemRef: itemRef,
  );
  return ref != null;
}
