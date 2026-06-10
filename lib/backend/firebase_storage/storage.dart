import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime_type/mime_type.dart';

import '/backend/firebase/app_environment.dart';
import '/backend/image_compress_helpers.dart';

class UploadDataResult {
  const UploadDataResult._({
    this.downloadUrl,
    this.errorCode,
    this.errorMessage,
  });

  const UploadDataResult.success(String url)
      : this._(downloadUrl: url);

  const UploadDataResult.failure({
    String? errorCode,
    String? errorMessage,
  }) : this._(errorCode: errorCode, errorMessage: errorMessage);

  final String? downloadUrl;
  final String? errorCode;
  final String? errorMessage;

  bool get isSuccess => downloadUrl != null && downloadUrl!.isNotEmpty;
}

/// User-facing message when a Storage upload fails.
String storageUploadFailureMessage(UploadDataResult result) {
  final code = result.errorCode ?? '';
  final message = (result.errorMessage ?? '').toLowerCase();

  if (code == 'unauthenticated' || code == 'unauthorized') {
    return 'Image upload failed: please sign in again and retry.';
  }

  if (code == 'quota-exceeded' ||
      message.contains('quota') ||
      message.contains('exceeded')) {
    return 'Image upload failed: Firebase Storage quota exceeded for '
        '$firebaseProjectId. Open Firebase Console → Storage (delete old files) '
        'or Project Settings → Usage and billing → upgrade plan.';
  }

  if (isStaging &&
      (code == 'unknown' ||
          code == 'object-not-found' ||
          message.contains('404') ||
          message.contains('not found') ||
          message.contains('does not exist'))) {
    return 'Image upload failed: Firebase Storage is not enabled on staging. '
        'Open Firebase Console → Storage → Get Started for project '
        '$firebaseProjectId, then run npm run deploy:storage:staging.';
  }

  if (code.isNotEmpty) {
    return 'Image upload failed ($code). Check login and Storage rules.';
  }

  return 'Image upload failed. Check login and Storage rules, then try again.';
}

Future<UploadDataResult> uploadDataWithResult(String path, Uint8List data) async {
  try {
    final payload = looksLikeImageBytes(data)
        ? await compressImageBytesForUpload(data)
        : data;
    final storageRef = FirebaseStorage.instance.ref().child(path);
    final contentType = _resolveContentType(path, payload);
    final metadata = SettableMetadata(contentType: contentType);
    final result = await storageRef.putData(payload, metadata);
    if (result.state != TaskState.success) {
      return const UploadDataResult.failure(
        errorCode: 'upload-failed',
        errorMessage: 'Upload did not complete',
      );
    }
    final url = await result.ref.getDownloadURL();
    return UploadDataResult.success(url);
  } on FirebaseException catch (e) {
    return UploadDataResult.failure(
      errorCode: e.code,
      errorMessage: e.message,
    );
  }
}

Future<String?> uploadData(String path, Uint8List data) async {
  final result = await uploadDataWithResult(path, data);
  return result.downloadUrl;
}

String? _guessImageContentType(Uint8List data) {
  if (data.length >= 3 && data[0] == 0xFF && data[1] == 0xD8) {
    return 'image/jpeg';
  }
  if (data.length >= 8 &&
      data[0] == 0x89 &&
      data[1] == 0x50 &&
      data[2] == 0x4E &&
      data[3] == 0x47) {
    return 'image/png';
  }
  if (data.length >= 6 &&
      data[0] == 0x47 &&
      data[1] == 0x49 &&
      data[2] == 0x46) {
    return 'image/gif';
  }
  return 'application/octet-stream';
}

String _resolveContentType(String path, Uint8List data) {
  return _guessImageContentType(data) ??
      mime(path) ??
      'application/octet-stream';
}
