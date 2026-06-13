import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;

import '/backend/product_edit_helpers.dart';
import '/backend/schema/companies_record.dart';

/// Loads company logo bytes for PDF headers (Firebase URL, gs://, or storage folder).
Future<pw.MemoryImage?> loadPdfCompanyLogoImage(
  CompaniesRecord? company,
) async {
  if (company == null) {
    return null;
  }

  final resolvedUrl = await resolveProductDisplayUrl(
    imageUrl: company.logo,
    productId: company.reference.id,
    storageFolderPrefix: 'company_logos',
  );

  Uint8List? bytes;
  if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
    bytes = await _fetchImageBytes(resolvedUrl);
  }

  if ((bytes == null || bytes.isEmpty) && company.reference.id.isNotEmpty) {
    try {
      final list = await FirebaseStorage.instance
          .ref('company_logos/${company.reference.id}')
          .listAll();
      if (list.items.isNotEmpty) {
        bytes = await list.items.first.getData();
      }
    } catch (_) {
      // Logo is optional.
    }
  }

  if (bytes == null || bytes.isEmpty) {
    return null;
  }
  return pw.MemoryImage(bytes);
}

Future<Uint8List?> _fetchImageBytes(String url) async {
  try {
    if (url.contains('firebasestorage.googleapis.com')) {
      try {
        final data = await FirebaseStorage.instance.refFromURL(url).getData();
        if (data != null && data.isNotEmpty) {
          return data;
        }
      } catch (_) {
        // Fall back to HTTP below.
      }
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      return response.bodyBytes;
    }
  } catch (_) {
    // Logo is optional.
  }
  return null;
}

/// Centered logo block for PDF letterheads.
pw.Widget buildPdfCompanyLogoHeader(pw.MemoryImage logoImage) {
  return pw.Column(
    children: [
      pw.Center(
        child: pw.SizedBox(
          height: 72,
          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
        ),
      ),
      pw.SizedBox(height: 16),
    ],
  );
}
