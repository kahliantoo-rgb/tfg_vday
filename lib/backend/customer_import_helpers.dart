import 'dart:typed_data';

import '/backend/customer_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/backend/product_import_helpers.dart' show parseSpreadsheetRows;
import '/backend/tenant_query_helpers.dart';

class CustomerImportRow {
  const CustomerImportRow({
    required this.lineNumber,
    required this.name,
    required this.phone,
    this.email,
    this.billingAddress,
    this.uen,
    this.isCreditCustomer = false,
    this.creditTerm,
    this.error,
  });

  final int lineNumber;
  final String name;
  final String phone;
  final String? email;
  final String? billingAddress;
  final String? uen;
  final bool isCreditCustomer;
  final String? creditTerm;
  final String? error;

  bool get isValid => error == null && name.isNotEmpty && phone.isNotEmpty;
}

class CustomerImportParseResult {
  const CustomerImportParseResult({
    required this.rows,
    required this.fileLabel,
  });

  final List<CustomerImportRow> rows;
  final String fileLabel;

  int get validCount => rows.where((row) => row.isValid).length;

  int get errorCount => rows.where((row) => row.error != null).length;
}

class CustomerImportWriteResult {
  const CustomerImportWriteResult({
    required this.created,
    required this.skippedDuplicates,
    required this.failed,
    required this.messages,
  });

  final int created;
  final int skippedDuplicates;
  final int failed;
  final List<String> messages;
}

const _nameHeaders = {
  'name',
  'customer name',
  'customer',
  'client name',
  'client',
  'full name',
};
const _phoneHeaders = {
  'phone',
  'mobile',
  'contact',
  'telephone',
  'phone number',
  'contact number',
};
const _emailHeaders = {
  'email',
  'e-mail',
  'email address',
  'mail',
};
const _billingHeaders = {
  'billing address',
  'billing_address',
  'address',
  'billing',
};
const _uenHeaders = {'uen', 'business registration', 'registration'};
const _creditHeaders = {
  'credit customer',
  'is credit customer',
  'is_credit_customer',
  'credit',
};
const _creditTermHeaders = {
  'credit term',
  'credit terms',
  'credit_term',
  'terms',
  'payment terms',
};

int? _columnIndex(Map<String, int> headerIndex, Set<String> aliases) {
  for (final alias in aliases) {
    final index = headerIndex[alias];
    if (index != null) {
      return index;
    }
  }
  return null;
}

String _cell(List<String> row, int? index) {
  if (index == null || index < 0 || index >= row.length) {
    return '';
  }
  return row[index].trim();
}

bool? _parseYesNo(String raw) {
  final value = raw.trim().toLowerCase();
  if (value.isEmpty) {
    return null;
  }
  if ({'yes', 'y', 'true', '1'}.contains(value)) {
    return true;
  }
  if ({'no', 'n', 'false', '0'}.contains(value)) {
    return false;
  }
  return null;
}

bool _looksLikeHeaderRow(List<String> row) {
  final normalized = row.map((cell) => cell.trim().toLowerCase()).toList();
  return normalized.any(_nameHeaders.contains) ||
      normalized.any(_phoneHeaders.contains);
}

Map<String, int> _headerIndex(List<String> headerRow) {
  final map = <String, int>{};
  for (var i = 0; i < headerRow.length; i++) {
    final key = headerRow[i].trim().toLowerCase();
    if (key.isNotEmpty) {
      map[key] = i;
    }
  }
  return map;
}

bool _isValidImportPhone(String phone) => isValidCustomerPhone(phone);

CustomerImportParseResult parseCustomerImportFile({
  required Uint8List bytes,
  required String filename,
}) {
  final rawRows = parseSpreadsheetRows(bytes: bytes, filename: filename);
  if (rawRows.isEmpty) {
    throw CustomerImportException('The file is empty.');
  }

  var dataRows = rawRows;
  Map<String, int>? headers;
  if (_looksLikeHeaderRow(rawRows.first)) {
    headers = _headerIndex(rawRows.first);
    dataRows = rawRows.skip(1).toList();
  }

  final nameIndex = headers != null
      ? _columnIndex(headers, _nameHeaders)
      : (rawRows.first.isNotEmpty ? 0 : null);
  final phoneIndex =
      headers != null ? _columnIndex(headers, _phoneHeaders) : 1;
  final emailIndex =
      headers != null ? _columnIndex(headers, _emailHeaders) : 2;
  final billingIndex =
      headers != null ? _columnIndex(headers, _billingHeaders) : 3;
  final uenIndex = headers != null ? _columnIndex(headers, _uenHeaders) : 4;
  final creditIndex =
      headers != null ? _columnIndex(headers, _creditHeaders) : null;
  final creditTermIndex =
      headers != null ? _columnIndex(headers, _creditTermHeaders) : null;

  if (nameIndex == null || phoneIndex == null) {
    throw CustomerImportException(
      'Missing required columns. Include at least Name and Phone '
      '(header row recommended).',
    );
  }

  final parsed = <CustomerImportRow>[];
  var lineNumber = headers != null ? 2 : 1;
  for (final row in dataRows) {
    final name = _cell(row, nameIndex);
    final phone = _cell(row, phoneIndex);
    final email = _cell(row, emailIndex);
    final billing = _cell(row, billingIndex);
    final uen = _cell(row, uenIndex);
    final creditRaw = _cell(row, creditIndex);
    final creditTermRaw = _cell(row, creditTermIndex);

    String? error;
    if (name.isEmpty) {
      error = 'Customer name is required';
    } else if (phone.isEmpty) {
      error = 'Phone is required';
    } else if (!_isValidImportPhone(phone)) {
      error = 'Phone must have $kCustomerPhoneMinDigits–$kCustomerPhoneMaxDigits '
          'digits (include country code for overseas numbers)';
    } else if (email.isNotEmpty) {
      final emailError = validateCustomerEmailInput(email);
      if (emailError != null) {
        error = emailError;
      }
    }

    final isCredit = _parseYesNo(creditRaw) ?? false;
    String? creditTerm;
    if (isCredit) {
      if (creditTermRaw.isEmpty) {
        error ??= 'Credit term is required for credit customers';
      } else {
        creditTerm = parseCustomCreditTerm(creditTermRaw);
      }
    }

    parsed.add(
      CustomerImportRow(
        lineNumber: lineNumber,
        name: name,
        phone: phone,
        email: email.isNotEmpty ? email : null,
        billingAddress: billing.isNotEmpty ? billing : null,
        uen: uen.isNotEmpty ? uen : null,
        isCreditCustomer: isCredit,
        creditTerm: creditTerm,
        error: error,
      ),
    );
    lineNumber++;
  }

  if (parsed.isEmpty) {
    throw CustomerImportException('No customer rows found in the file.');
  }

  return CustomerImportParseResult(
    rows: parsed,
    fileLabel: filename,
  );
}

Future<CustomerImportWriteResult> writeImportedCustomers(
  List<CustomerImportRow> rows, {
  required bool allowCreditCustomers,
}) async {
  final validRows = rows.where((row) => row.isValid).toList();
  if (validRows.isEmpty) {
    return const CustomerImportWriteResult(
      created: 0,
      skippedDuplicates: 0,
      failed: 0,
      messages: ['No valid rows to import.'],
    );
  }

  final existing = await queryTenantCustomersRecordOnce(limit: 2000);
  final existingPhones = existing
      .map((customer) => normalizeCustomerPhone(customer.phone))
      .where((phone) => phone.isNotEmpty)
      .toSet();
  final existingNames = existing
      .map((customer) => normalizeCustomerName(customer.name))
      .where((name) => name.isNotEmpty)
      .toSet();

  var created = 0;
  var skippedDuplicates = 0;
  var failed = 0;
  final messages = <String>[];

  for (final row in validRows) {
    final phoneKey = normalizeCustomerPhone(row.phone);
    final nameKey = normalizeCustomerName(row.name);
    if (existingPhones.contains(phoneKey)) {
      skippedDuplicates++;
      messages.add(
        'Line ${row.lineNumber}: skipped duplicate phone ${row.phone}',
      );
      continue;
    }
    if (existingNames.contains(nameKey)) {
      skippedDuplicates++;
      messages.add(
        'Line ${row.lineNumber}: skipped duplicate name ${row.name}',
      );
      continue;
    }

    final applyCredit = allowCreditCustomers && row.isCreditCustomer;
    if (row.isCreditCustomer && !allowCreditCustomers) {
      messages.add(
        'Line ${row.lineNumber}: imported without credit (no permission)',
      );
    }

    try {
      final result = await createCustomerProfile(
        name: row.name,
        phone: row.phone,
        email: row.email,
        billingAddress: row.billingAddress,
        uen: row.uen,
        isCreditCustomer: applyCredit,
        creditTerm: applyCredit ? row.creditTerm : null,
      );
      if (result == null) {
        failed++;
        messages.add('Line ${row.lineNumber}: company not selected');
        continue;
      }
      existingPhones.add(phoneKey);
      existingNames.add(nameKey);
      created++;
    } catch (error) {
      failed++;
      messages.add('Line ${row.lineNumber}: $error');
    }
  }

  return CustomerImportWriteResult(
    created: created,
    skippedDuplicates: skippedDuplicates,
    failed: failed,
    messages: messages,
  );
}

class CustomerImportException implements Exception {
  CustomerImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
