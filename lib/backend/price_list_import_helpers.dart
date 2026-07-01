import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/price_list_helpers.dart';
import '/backend/product_import_helpers.dart' show parseSpreadsheetRows;
import '/backend/tenant_query_helpers.dart';
import '/custom_code/actions/csv_export_helpers.dart';

class PriceListImportRow {
  const PriceListImportRow({
    required this.lineNumber,
    required this.sku,
    required this.price,
    this.productName,
    this.error,
  });

  final int lineNumber;
  final String sku;
  final double price;
  final String? productName;
  final String? error;

  bool get isValid => error == null && sku.isNotEmpty && price > 0;
}

class PriceListImportParseResult {
  const PriceListImportParseResult({
    required this.rows,
    required this.fileLabel,
  });

  final List<PriceListImportRow> rows;
  final String fileLabel;

  int get validCount => rows.where((row) => row.isValid).length;

  int get errorCount => rows.where((row) => row.error != null).length;
}

class PriceListImportWriteResult {
  const PriceListImportWriteResult({
    required this.imported,
    required this.unmatchedSkus,
    required this.messages,
  });

  final int imported;
  final List<String> unmatchedSkus;
  final List<String> messages;
}

const priceListImportTemplateHeaders = ['SKU', 'Product Name', 'Price'];

const _skuHeaders = {'sku', 'product code', 'code', 'product_code'};
const _nameHeaders = {
  'product name',
  'name',
  'product',
  'product_name',
  'description',
};
const _priceHeaders = {'price', 'unit price', 'contract price', 'unit_price'};

String priceListImportTemplateCsv() {
  const rows = [
    ['FL01', 'Hand Bouquet Standard', '180'],
    ['FL02', 'Opening Stand Deluxe', '220'],
    ['WR-01', 'Condolence Wreath', '160'],
  ];
  final buffer = StringBuffer();
  buffer.writeln(priceListImportTemplateHeaders.join(','));
  for (final row in rows) {
    buffer.writeln(row.join(','));
  }
  return buffer.toString();
}

Uint8List priceListImportTemplateBytes() =>
    encodeCsvUtf8Bytes(priceListImportTemplateCsv());

bool _looksLikeHeaderRow(List<String> row) {
  final normalized = row.map((cell) => cell.trim().toLowerCase()).toList();
  return normalized.any(_skuHeaders.contains) ||
      normalized.any(_priceHeaders.contains);
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

double? _parsePrice(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^\d.-]'), '').trim();
  if (cleaned.isEmpty) {
    return null;
  }
  return double.tryParse(cleaned);
}

PriceListImportParseResult parsePriceListImportFile({
  required Uint8List bytes,
  required String filename,
}) {
  final spreadsheet = parseSpreadsheetRows(bytes: bytes, filename: filename);
  if (spreadsheet.isEmpty) {
    return PriceListImportParseResult(rows: const [], fileLabel: filename);
  }

  var startIndex = 0;
  Map<String, int>? headerIndex;
  if (_looksLikeHeaderRow(spreadsheet.first)) {
    headerIndex = _headerIndex(spreadsheet.first);
    startIndex = 1;
  }

  final skuCol = headerIndex == null
      ? 0
      : _columnIndex(headerIndex, _skuHeaders) ?? 0;
  final nameCol = headerIndex == null
      ? 1
      : _columnIndex(headerIndex, _nameHeaders);
  final priceCol = headerIndex == null
      ? 2
      : _columnIndex(headerIndex, _priceHeaders) ?? 2;

  final rows = <PriceListImportRow>[];
  for (var i = startIndex; i < spreadsheet.length; i++) {
    final row = spreadsheet[i];
    if (row.every((cell) => cell.trim().isEmpty)) {
      continue;
    }
    final lineNumber = i + 1;
    final sku = _cell(row, skuCol);
    final productName = _cell(row, nameCol);
    final priceRaw = _cell(row, priceCol);
    final price = _parsePrice(priceRaw);

    String? error;
    if (sku.isEmpty) {
      error = 'SKU is required';
    } else if (price == null || price <= 0) {
      error = 'Price must be greater than zero';
    }

    rows.add(
      PriceListImportRow(
        lineNumber: lineNumber,
        sku: sku,
        price: price ?? 0,
        productName: productName.isEmpty ? null : productName,
        error: error,
      ),
    );
  }

  return PriceListImportParseResult(rows: rows, fileLabel: filename);
}

Future<PriceListImportWriteResult> writeImportedPriceListLines({
  required DocumentReference priceListRef,
  required List<PriceListImportRow> rows,
}) async {
  final validRows = rows.where((row) => row.isValid).toList();
  if (validRows.isEmpty) {
    return const PriceListImportWriteResult(
      imported: 0,
      unmatchedSkus: [],
      messages: ['No valid rows to import.'],
    );
  }

  final products = await queryTenantProductRecordOnce();
  final productsBySku = buildProductCatalogBySku(products);
  final unmatchedSkus = <String>[];
  final lines = <PriceListLine>[];

  for (final row in validRows) {
    final product = productsBySku[normalizePriceListSku(row.sku)];
    if (product == null) {
      unmatchedSkus.add(row.sku);
      lines.add(
        PriceListLine(
          sku: row.sku,
          price: row.price,
          productName: row.productName ?? '',
        ),
      );
      continue;
    }
    lines.add(
      PriceListLine(
        sku: product.sku.isNotEmpty ? product.sku : row.sku,
        price: row.price,
        productRef: product.reference,
        productName: product.name.isNotEmpty
            ? product.name
            : (row.productName ?? ''),
      ),
    );
  }

  await upsertPriceListLines(priceListRef: priceListRef, incoming: lines);

  final messages = <String>[
    'Imported ${validRows.length} price line(s).',
  ];
  if (unmatchedSkus.isNotEmpty) {
    messages.add(
      '${unmatchedSkus.length} SKU(s) not found in product catalog '
      '(saved by SKU; link products when catalog is updated).',
    );
  }

  return PriceListImportWriteResult(
    imported: validRows.length,
    unmatchedSkus: unmatchedSkus,
    messages: messages,
  );
}
