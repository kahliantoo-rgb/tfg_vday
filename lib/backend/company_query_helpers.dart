import '/backend/backend.dart';
import '/backend/schema/companies_record.dart';

/// Filters [companies] by name, phone, UEN, ID, or address (case-insensitive).
List<CompaniesRecord> filterCompaniesBySearchQuery(
  List<CompaniesRecord> companies,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return companies;
  }
  return companies.where((c) {
    return c.companyName.toLowerCase().contains(q) ||
        c.companyPhone.toLowerCase().contains(q) ||
        c.companyUen.toLowerCase().contains(q) ||
        c.companyId.toLowerCase().contains(q) ||
        c.companyAddress.toLowerCase().contains(q);
  }).toList();
}

/// Deterministic default company (alphabetical first active, else first by name).
Stream<List<CompaniesRecord>> queryDefaultCompanyRecord() =>
    queryCompaniesRecord(
      queryBuilder: (q) => q.orderBy('Company_name').limit(1),
    );

Future<CompaniesRecord?> getDefaultCompanyOnce() async {
  final records = await queryCompaniesRecordOnce(
    queryBuilder: (q) => q.orderBy('Company_name').limit(1),
  );
  return records.isNotEmpty ? records.first : null;
}
