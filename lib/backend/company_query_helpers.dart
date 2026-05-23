import '/backend/backend.dart';
import '/backend/schema/companies_record.dart';

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
