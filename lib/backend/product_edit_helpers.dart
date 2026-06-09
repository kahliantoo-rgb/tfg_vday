import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/schema/product_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/upload_data.dart';

final _resolvedImageUrlCache = <String, String>{};

/// Coerces FlutterFlow / legacy Firestore image values to a URL string.
String? coerceProductImageUrl(dynamic raw) {
  if (raw == null) {
    return null;
  }
  if (raw is String) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (raw is Map) {
    for (final key in ['url', 'path', 'downloadUrl', 'download_url']) {
      final nested = coerceProductImageUrl(raw[key]);
      if (nested != null) {
        return nested;
      }
    }
  }
  return null;
}

/// Reads product image URL from Firestore (supports legacy `Image` field).
String productImageFromRecord(ProductRecord product) {
  final primary = coerceProductImageUrl(product.snapshotData['image']);
  if (primary != null) {
    return primary;
  }
  final legacy = coerceProductImageUrl(product.snapshotData['Image']);
  if (legacy != null) {
    return legacy;
  }
  return '';
}

bool isRelativeStoragePath(String url) {
  final trimmed = url.trim();
  return trimmed.isNotEmpty &&
      !trimmed.startsWith('http://') &&
      !trimmed.startsWith('https://') &&
      !trimmed.startsWith('gs://') &&
      trimmed.contains('/');
}

bool isUsableImageUrl(String? url) {
  if (url == null || url.isEmpty) {
    return false;
  }
  return url.startsWith('http') ||
      url.startsWith('gs://') ||
      isRelativeStoragePath(url);
}

String? firebaseObjectPathFromDownloadUrl(String url) {
  const marker = '/o/';
  final start = url.indexOf(marker);
  if (start < 0) {
    return null;
  }
  final encoded = url.substring(start + marker.length).split('?').first;
  return Uri.decodeComponent(encoded);
}

/// True when a Firebase Storage download URL has the expected shape.
bool isValidFirebaseStorageDownloadUrl(String url) {
  if (!url.startsWith('https://firebasestorage.googleapis.com/')) {
    return false;
  }
  if (!url.contains('?alt=media') || !url.contains('&token=')) {
    return false;
  }
  final objectPath = firebaseObjectPathFromDownloadUrl(url);
  if (objectPath == null || objectPath.isEmpty) {
    return false;
  }
  final segments =
      objectPath.split('/').where((segment) => segment.isNotEmpty).toList();
  return segments.length >= 3;
}

/// Fixes URLs where `?alt=media` lost the leading question mark.
String? repairFirebaseStorageDownloadUrl(String url) {
  if (!url.contains('firebasestorage.googleapis.com')) {
    return null;
  }
  if (url.contains('?alt=media')) {
    return null;
  }
  if (url.contains('alt=media')) {
    return url.replaceFirst('alt=media', '?alt=media');
  }
  return null;
}

String safeProductImageFilename(String filename) {
  final trimmed = filename.trim();
  if (trimmed.isNotEmpty) {
    return trimmed.replaceAll(RegExp(r'[^\w.\-]'), '_');
  }
  return 'photo.jpg';
}

/// Normalizes http(s), gs://, or relative storage paths to a browser URL.
Future<String?> resolveProductImageUrl(String? raw) async {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final cached = _resolvedImageUrlCache[trimmed];
  if (cached != null) {
    return cached;
  }
  if (trimmed.startsWith('gs://')) {
    try {
      final url =
          await FirebaseStorage.instance.refFromURL(trimmed).getDownloadURL();
      _resolvedImageUrlCache[trimmed] = url;
      return url;
    } on FirebaseException {
      return null;
    }
  }
  if (isRelativeStoragePath(trimmed)) {
    try {
      final url = await FirebaseStorage.instance.ref(trimmed).getDownloadURL();
      _resolvedImageUrlCache[trimmed] = url;
      return url;
    } on FirebaseException {
      return null;
    }
  }
  return null;
}

/// Loads the first uploaded file under `{folderPrefix}/{entityId}/`.
Future<String?> resolveProductImageFromStorageFolder(
  String entityId, {
  String folderPrefix = 'product_images',
  DocumentReference? repairProductRef,
}) async {
  final cacheKey = 'folder:$folderPrefix:$entityId';
  final cached = _resolvedImageUrlCache[cacheKey];
  if (cached != null) {
    return cached;
  }
  try {
    final list = await FirebaseStorage.instance
        .ref('$folderPrefix/$entityId')
        .listAll();
    if (list.items.isEmpty) {
      return null;
    }
    final url = await list.items.first.getDownloadURL();
    _resolvedImageUrlCache[cacheKey] = url;
    if (repairProductRef != null && isValidFirebaseStorageDownloadUrl(url)) {
      unawaited(persistProductImageUrl(repairProductRef, url));
    }
    return url;
  } on FirebaseException {
    return null;
  }
}

/// Resolves a displayable image URL, recovering from corrupted Firestore values.
Future<String?> resolveProductDisplayUrl({
  String? imageUrl,
  String? productId,
  DocumentReference? productRef,
  String storageFolderPrefix = 'product_images',
}) async {
  final raw = imageUrl?.trim() ?? '';
  final id = productId ?? productRef?.id;

  if (raw.isNotEmpty) {
    if (raw.startsWith('http') &&
        !raw.contains('firebasestorage.googleapis.com')) {
      return raw;
    }
    if (isValidFirebaseStorageDownloadUrl(raw)) {
      return raw;
    }
    final repaired = repairFirebaseStorageDownloadUrl(raw);
    if (repaired != null && isValidFirebaseStorageDownloadUrl(repaired)) {
      return repaired;
    }
    if (!raw.startsWith('http')) {
      final resolved = await resolveProductImageUrl(raw);
      if (resolved != null &&
          (isValidFirebaseStorageDownloadUrl(resolved) ||
              !resolved.contains('firebasestorage.googleapis.com'))) {
        return resolved;
      }
    }
  }

  if (id != null && id.isNotEmpty) {
    return resolveProductImageFromStorageFolder(
      id,
      folderPrefix: storageFolderPrefix,
      repairProductRef: productRef,
    );
  }
  return null;
}

/// Best-effort URL for immediate network display (repairs common corruption).
String? _directFirebaseStorageUrl(String? imageUrl) {
  final raw = imageUrl?.trim() ?? '';
  if (raw.isEmpty) {
    return null;
  }
  if (isValidFirebaseStorageDownloadUrl(raw)) {
    return raw;
  }
  if (raw.startsWith('https://firebasestorage.googleapis.com/') &&
      raw.contains('/o/')) {
    final repaired = repairFirebaseStorageDownloadUrl(raw);
    if (repaired != null && isValidFirebaseStorageDownloadUrl(repaired)) {
      return repaired;
    }
    if (raw.contains('alt=media')) {
      return raw;
    }
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  return null;
}

/// Product photo thumbnail used across catalog, order, and create flows.
Future<void> showEnlargedProductImageDialog(
  BuildContext context, {
  String? imageUrl,
  Uint8List? localBytes,
  String? productId,
  DocumentReference? productRef,
  String? title,
  String storageFolderPrefix = 'product_images',
}) async {
  final id = productId ?? productRef?.id;
  final hasLocalImage = localBytes != null && localBytes.isNotEmpty;
  final hasRemoteImage = isUsableImageUrl(imageUrl) || (id != null && id.isNotEmpty);
  if (!hasLocalImage && !hasRemoteImage) {
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.92,
            maxHeight: size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null && title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(dialogContext).titleMedium,
                  ),
                ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: hasLocalImage
                        ? Image.memory(localBytes, fit: BoxFit.contain)
                        : FutureBuilder<String?>(
                            future: resolveProductDisplayUrl(
                              imageUrl: imageUrl,
                              productId: id,
                              productRef: productRef,
                              storageFolderPrefix: storageFolderPrefix,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final resolved = snapshot.data;
                              if (resolved == null || resolved.isEmpty) {
                                return const Center(
                                  child: Icon(Icons.image_not_supported_outlined),
                                );
                              }
                              return kIsWeb
                                  ? Image.network(
                                      resolved,
                                      fit: BoxFit.contain,
                                      webHtmlElementStrategy:
                                          WebHtmlElementStrategy.prefer,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: resolved,
                                      fit: BoxFit.contain,
                                    );
                            },
                          ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget buildZoomableProductImage({
  required BuildContext context,
  String? imageUrl,
  Uint8List? localBytes,
  String? productId,
  DocumentReference? productRef,
  String storageFolderPrefix = 'product_images',
  double width = 72.0,
  double height = 72.0,
  BoxFit fit = BoxFit.cover,
  IconData placeholderIcon = Icons.image_not_supported_outlined,
  String? title,
}) {
  final id = productId ?? productRef?.id;
  final hasLocalImage = localBytes != null && localBytes.isNotEmpty;
  final hasRemoteImage = isUsableImageUrl(imageUrl) || (id != null && id.isNotEmpty);

  return GestureDetector(
    onTap: hasLocalImage || hasRemoteImage
        ? () => showEnlargedProductImageDialog(
              context,
              imageUrl: imageUrl,
              localBytes: localBytes,
              productId: id,
              productRef: productRef,
              title: title,
              storageFolderPrefix: storageFolderPrefix,
            )
        : null,
    child: buildProductImage(
      context: context,
      imageUrl: imageUrl,
      localBytes: localBytes,
      productId: productId,
      productRef: productRef,
      storageFolderPrefix: storageFolderPrefix,
      width: width,
      height: height,
      fit: fit,
      placeholderIcon: placeholderIcon,
    ),
  );
}

Widget buildProductImage({
  required BuildContext context,
  String? imageUrl,
  Uint8List? localBytes,
  String? productId,
  DocumentReference? productRef,
  String storageFolderPrefix = 'product_images',
  double width = 72.0,
  double height = 72.0,
  BoxFit fit = BoxFit.cover,
  IconData placeholderIcon = Icons.image_not_supported_outlined,
}) {
  final theme = FlutterFlowTheme.of(context);
  final placeholder = Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: theme.alternate,
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Icon(
      placeholderIcon,
      color: theme.secondaryText,
    ),
  );

  if (localBytes != null && localBytes.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.memory(
        localBytes,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }

  final id = productId ?? productRef?.id;
  if (!isUsableImageUrl(imageUrl) && (id == null || id.isEmpty)) {
    return placeholder;
  }

  final directUrl = _directFirebaseStorageUrl(imageUrl);
  if (directUrl != null) {
    return _networkProductImage(
      url: directUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      productRef: productRef,
      productId: id,
      storageFolderPrefix: storageFolderPrefix,
    );
  }

  return FutureBuilder<String?>(
    key: ValueKey('${id ?? ''}|$imageUrl|$storageFolderPrefix'),
    future: resolveProductDisplayUrl(
      imageUrl: imageUrl,
      productId: id,
      productRef: productRef,
      storageFolderPrefix: storageFolderPrefix,
    ),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return placeholder;
      }
      final resolved = snapshot.data;
      if (resolved == null || resolved.isEmpty) {
        return placeholder;
      }
      return _networkProductImage(
        url: resolved,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        productId: id,
        productRef: productRef,
        storageFolderPrefix: storageFolderPrefix,
      );
    },
  );
}

Widget _networkProductImage({
  required String url,
  required double width,
  required double height,
  required BoxFit fit,
  required Widget placeholder,
  String? productId,
  DocumentReference? productRef,
  String storageFolderPrefix = 'product_images',
}) {
  Widget fallbackOnError() {
    if (productId == null && productRef == null) {
      return placeholder;
    }
    return FutureBuilder<String?>(
      future: resolveProductImageFromStorageFolder(
        productId ?? productRef!.id,
        folderPrefix: storageFolderPrefix,
        repairProductRef: productRef,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder;
        }
        final fallback = snapshot.data;
        if (fallback == null || fallback.isEmpty) {
          return placeholder;
        }
        return kIsWeb
            ? Image.network(
                fallback,
                width: width,
                height: height,
                fit: fit,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => placeholder,
              )
            : CachedNetworkImage(
                imageUrl: fallback,
                width: width,
                height: height,
                fit: fit,
                placeholder: (_, __) => placeholder,
                errorWidget: (_, __, ___) => placeholder,
              );
      },
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(8.0),
    child: kIsWeb
        ? Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return placeholder;
            },
            errorBuilder: (_, __, ___) => fallbackOnError(),
          )
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, __) => placeholder,
            errorWidget: (_, __, ___) => fallbackOnError(),
          ),
  );
}

/// Storage path for a product image upload.
String productImageStoragePath(String productId, String filename) {
  final safeName = safeProductImageFilename(filename);
  return 'product_images/$productId/$safeName';
}

/// Uploads bytes to Storage only (no Firestore write). Safe before product doc exists.
Future<UploadDataResult> uploadProductImageBytes({
  required String productId,
  required Uint8List bytes,
  required String filename,
}) =>
    uploadDataWithResult(
      productImageStoragePath(productId, filename),
      bytes,
    );

Map<String, dynamic> productImageFirestoreFields(String downloadUrl) => {
      ...createProductRecordData(image: downloadUrl),
      'Image': downloadUrl,
    };

/// Result of a successful product image pick + upload.
class ProductImageUploadResult {
  const ProductImageUploadResult({
    required this.downloadUrl,
    required this.previewBytes,
  });

  final String downloadUrl;
  final Uint8List previewBytes;
}

/// Writes [image] (+ legacy [Image]) on the product doc.
Future<bool> persistProductImageUrl(
  DocumentReference productRef,
  String downloadUrl,
) async {
  if (!isValidFirebaseStorageDownloadUrl(downloadUrl)) {
    return false;
  }
  await productRef.update(productImageFirestoreFields(downloadUrl));
  return true;
}

/// Uploads bytes to Storage and persists the download URL on the product doc.
Future<ProductImageUploadResult?> uploadBytesAndPersistProductImage({
  required BuildContext context,
  required DocumentReference productRef,
  required Uint8List bytes,
  required String filename,
  bool showSuccessSnackbar = true,
}) async {
  if (!loggedIn) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to upload photos.'),
        ),
      );
    }
    return null;
  }

  final uploadResult = await uploadDataWithResult(
    productImageStoragePath(productRef.id, filename),
    bytes,
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
          content: Text(
            'Upload returned an invalid image URL. Please try again.',
          ),
        ),
      );
    }
    return null;
  }

  try {
    final saved = await persistProductImageUrl(productRef, downloadUrl);
    if (!saved) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Upload OK but product image was not saved. Check Firestore permissions.',
            ),
          ),
        );
      }
      return null;
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload OK but saving product failed: $e')),
      );
    }
    return null;
  }

  if (showSuccessSnackbar && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo updated')),
    );
  }
  return ProductImageUploadResult(
    downloadUrl: downloadUrl,
    previewBytes: bytes,
  );
}

/// Picks an image, uploads to Storage, and writes [image] on the product doc.
Future<ProductImageUploadResult?> pickAndUploadProductImage({
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
  return uploadBytesAndPersistProductImage(
    context: context,
    productRef: productRef,
    bytes: media.bytes,
    filename: filename,
  );
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
