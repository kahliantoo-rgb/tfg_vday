import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/order_production_menu_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';

String deliveryProofStoragePath(String orderId, String filename) {
  final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  return 'delivery_proof_images/$orderId/$safeName';
}

const int maxDeliveryProofPhotos = 5;

List<String> resolvedDeliveryProofUrls(OrdersRecord order) {
  final fromList =
      order.deliveryProofUrls.where((url) => url.trim().isNotEmpty).toList();
  if (fromList.isNotEmpty) {
    return fromList;
  }
  final single = order.deliveryProofUrl.trim();
  if (single.isNotEmpty) {
    return [single];
  }
  return const [];
}

bool orderAllowsDeliveryProofUpload(OrderStatus? status) {
  return status == OrderStatus.out_of_delivery ||
      status == OrderStatus.completed;
}

Future<String?> ensureReadyForDeliveryProofUpload(OrdersRecord order) async {
  try {
    await ensureTenantContextForOrder(order);
  } on FirebaseException catch (error) {
    return error.message ?? 'Could not prepare company access for upload.';
  }

  final profile =
      TenantContext.instance.profile ?? await resolveCurrentUserProfile();
  if (profile == null) {
    return 'User profile not found. Ask admin to set up users/{uid}.';
  }

  if (order.assignedDriver?.path != profile.reference.path) {
    return 'This delivery is not assigned to your account.';
  }

  if (!order.hasCompanyRef()) {
    return 'This order has no company assigned. Ask admin to fix the order record.';
  }

  return null;
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

  final blocked = await ensureReadyForDeliveryProofUpload(order);
  if (blocked != null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked)),
      );
    }
    return false;
  }

  final existingUrls = resolvedDeliveryProofUrls(order);
  final remainingSlots = maxDeliveryProofPhotos - existingUrls.length;
  if (remainingSlots <= 0) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum $maxDeliveryProofPhotos delivery photos reached.',
          ),
        ),
      );
    }
    return false;
  }

  final selectedMedia = await selectMediaWithSourceBottomSheet(
    context: context,
    allowPhoto: true,
    // One photo per pick — tap again to add more (max 5 total). Not a minimum.
    multiImage: false,
  );
  if (selectedMedia == null ||
      selectedMedia.isEmpty ||
      !selectedMedia.every(
        (media) => validateFileFormat(media.storagePath, context),
      )) {
    return false;
  }

  final uploads = selectedMedia.take(remainingSlots).toList();
  if (uploads.length < selectedMedia.length && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Only ${uploads.length} photo(s) added (max $maxDeliveryProofPhotos total).',
        ),
      ),
    );
  }

  final uploadedUrls = <String>[];
  for (final media in uploads) {
    final filename = media.storagePath.split('/').last;
    final storagePath =
        deliveryProofStoragePath(order.reference.id, filename);
    final uploadResult = await uploadDataWithResult(storagePath, media.bytes);
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
    uploadedUrls.add(downloadUrl);
  }

  final mergedUrls = [...existingUrls, ...uploadedUrls];

  try {
    await order.reference.update(
      createOrdersRecordData(
        deliveryProofUrls: mergedUrls,
        deliveryProofUrl: mergedUrls.first,
        deliveryProofAt: getCurrentTimestamp,
      ),
    );
    await auditLogDeliveryProofUpload(
      order: order,
      previousPhotoCount: existingUrls.length,
      uploadedUrls: uploadedUrls,
      totalPhotoCount: mergedUrls.length,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uploadedUrls.length == 1
                ? 'Delivery proof uploaded.'
                : '${uploadedUrls.length} delivery photos uploaded.',
          ),
        ),
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
