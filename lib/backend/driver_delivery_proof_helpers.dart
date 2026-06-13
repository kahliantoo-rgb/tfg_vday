import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';

String deliveryProofStoragePath(String orderId, String filename) {
  final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  return 'delivery_proof_images/$orderId/$safeName';
}

bool orderAllowsDeliveryProofUpload(OrderStatus? status) {
  return status == OrderStatus.out_of_delivery ||
      status == OrderStatus.completed;
}

Future<bool> uploadOrderDeliveryProof({
  required BuildContext context,
  required OrdersRecord order,
}) async {
  if (!loggedIn) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upload delivery proof.')),
      );
    }
    return false;
  }

  if (!orderAllowsDeliveryProofUpload(order.status)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Start delivery first, then upload proof when delivering.',
          ),
        ),
      );
    }
    return false;
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
    return false;
  }

  final media = selectedMedia.first;
  final filename = media.storagePath.split('/').last;
  final uploadResult = await uploadDataWithResult(
    deliveryProofStoragePath(order.reference.id, filename),
    media.bytes,
  );
  if (!uploadResult.isSuccess) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(storageUploadFailureMessage(uploadResult))),
      );
    }
    return false;
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
    return false;
  }

  try {
    await order.reference.update(
      createOrdersRecordData(
        deliveryProofUrl: downloadUrl,
        deliveryProofAt: getCurrentTimestamp,
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery proof uploaded.')),
      );
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save delivery proof: $error')),
      );
    }
    return false;
  }
}
