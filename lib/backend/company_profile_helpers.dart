import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/firebase_storage/storage.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/flutter_flow/upload_data.dart';

/// Company document the current admin may edit.
DocumentReference? resolveCompanyRefForProfileEdit(UsersRecord? profile) {
  if (TenantContext.canViewAllCompanies(profile)) {
    return TenantContext.instance.writeCompanyRef;
  }
  return canonicalCompanyRef(
    profile?.companyRef ?? TenantContext.instance.activeCompanyRef,
  );
}

String companyLogoStoragePath(String companyId, String filename) {
  final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  return 'company_logos/$companyId/$safeName';
}

Future<CompaniesRecord> loadCompanyProfile(DocumentReference ref) =>
    CompaniesRecord.getDocumentOnce(ref);

Future<void> saveCompanyProfile({
  required DocumentReference companyRef,
  required String companyName,
  required String companyUen,
  required String companyPhone,
  required String companyAddress,
  required String logoUrl,
  bool? isActive,
}) async {
  await companyRef.update(
    createCompaniesRecordData(
      companyName: companyName,
      companyUen: companyUen,
      companyPhone: companyPhone,
      companyAddress: companyAddress,
      logo: logoUrl.isNotEmpty ? logoUrl : null,
      isActive: isActive,
    ),
  );

  if (TenantContext.instance.activeCompanyRef?.path == companyRef.path) {
    await TenantContext.instance.reloadActiveCompany();
  }
}

Future<String?> pickAndUploadCompanyLogo({
  required BuildContext context,
  required DocumentReference companyRef,
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
  final path = companyLogoStoragePath(companyRef.id, filename);
  final downloadUrl = await uploadData(path, media.bytes);
  if (downloadUrl == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo upload failed')),
      );
    }
    return null;
  }

  await companyRef.update(createCompaniesRecordData(logo: downloadUrl));
  if (TenantContext.instance.activeCompanyRef?.path == companyRef.path) {
    await TenantContext.instance.reloadActiveCompany();
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company logo updated')),
    );
  }
  return downloadUrl;
}

bool isUsableCompanyLogoUrl(String? url) => isUsableImageUrl(url);
