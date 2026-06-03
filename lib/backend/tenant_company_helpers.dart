import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/companies_record.dart';

/// Production company doc id (Firestore `Companies` collection).
const kCanonicalCompanyId = 'lc3Dhfby8f35Md0E1vZC';

/// Common typo: capital I instead of lowercase L.
const kTypoCompanyId = 'Ic3Dhfby8f35Md0E1vZC';

DocumentReference canonicalCompanyRef(DocumentReference? ref) {
  if (ref == null) {
    return CompaniesRecord.collection.doc(kCanonicalCompanyId);
  }
  if (ref.id == kTypoCompanyId) {
    return CompaniesRecord.collection.doc(kCanonicalCompanyId);
  }
  return ref;
}

String canonicalCompanyId(String? id) {
  if (id == null || id.isEmpty) {
    return kCanonicalCompanyId;
  }
  if (id == kTypoCompanyId) {
    return kCanonicalCompanyId;
  }
  return id;
}

bool isTypoCompanyId(String id) => id == kTypoCompanyId;
