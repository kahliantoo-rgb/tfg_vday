import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:xml/xml.dart';

import '/backend/backend.dart';
import '/backend/product_category_helpers.dart';
import '/backend/tenant_query_helpers.dart';

class ProductImportRow {
  const ProductImportRow({
    required this.lineNumber,
    required this.name,
    required this.sku,
    required this.price,
    this.category,
    this.isActive = true,
    this.imageUrl,
    this.error,
  });

  final int lineNumber;
  final String name;
  final String sku;
  final double price;
  final String? category;
  final bool isActive;
  final String? imageUrl;
  final String? error;

  bool get isValid => error == null && name.isNotEmpty && price > 0;
}

class ProductImportParseResult {
  const ProductImportParseResult({
    required this.rows,
    required this.fileLabel,
  });

  final List<ProductImportRow> rows;
  final String fileLabel;

  int get validCount => rows.where((row) => row.isValid).length;

  int get errorCount => rows.where((row) => row.error != null).length;
}

class ProductImportWriteResult {
  const ProductImportWriteResult({
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

const _nameHeaders = {'name', 'product name', 'product', 'product_name'};
const _skuHeaders = {'sku', 'code', 'product code', 'product_code'};
const _priceHeaders = {'price', 'unit price', 'amount', 'unit_price'};
const _categoryHeaders = {'category', 'cat', 'type', 'product category'};
const _activeHeaders = {'active', 'is active', 'isactive', 'is_active'};
const _imageHeaders = {'image', 'image url', 'photo', 'url', 'image_url'};

List<List<String>> parseSpreadsheetRows({
  required Uint8List bytes,
  required String filename,
}) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.csv') || lower.endsWith('.txt')) {
    return _parseCsvRows(bytes);
  }
  if (lower.endsWith('.xlsx')) {
    return _parseXlsxRows(bytes);
  }
  throw ProductImportException(
    'Unsupported file type. Use .csv or .xlsx (Excel).',
  );
}

List<List<String>> _parseCsvRows(Uint8List bytes) {
  var text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('\uFEFF')) {
    text = text.substring(1);
  }
  final rows = const CsvToListConverter(
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(text);
  return rows
      .map(
        (row) => row
            .map((cell) => cell?.toString().trim() ?? '')
            .toList(growable: false),
      )
      .where((row) => row.any((cell) => cell.isNotEmpty))
      .toList(growable: false);
}

List<List<String>> _parseXlsxRows(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final sharedStrings = _readXlsxSharedStrings(archive);
  final sheetXml = _readFirstXlsxWorksheetXml(archive);
  if (sheetXml == null) {
    return const [];
  }

  final document = XmlDocument.parse(sheetXml);
  final sheetData = document.rootElement
      .findAllElements('sheetData')
      .firstOrNull;
  if (sheetData == null) {
    return const [];
  }

  final grid = <int, Map<int, String>>{};
  var maxColumn = 0;
  for (final rowElement in sheetData.findElements('row')) {
    final rowNumber =
        int.tryParse(rowElement.getAttribute('r') ?? '') ?? grid.length + 1;
    final columns = <int, String>{};
    for (final cell in rowElement.findElements('c')) {
      final ref = cell.getAttribute('r') ?? '';
      final columnIndex = _columnIndexFromCellRef(ref);
      maxColumn = math.max(maxColumn, columnIndex);
      columns[columnIndex] = _readXlsxCellValue(cell, sharedStrings);
    }
    if (columns.isNotEmpty) {
      grid[rowNumber] = columns;
    }
  }

  if (grid.isEmpty) {
    return const [];
  }

  final minRow = grid.keys.reduce(math.min);
  final maxRow = grid.keys.reduce(math.max);
  final rows = <List<String>>[];
  for (var rowNumber = minRow; rowNumber <= maxRow; rowNumber++) {
    final columns = grid[rowNumber] ?? const {};
    final values = List<String>.generate(
      maxColumn + 1,
      (index) => columns[index]?.trim() ?? '',
      growable: false,
    );
    if (values.any((value) => value.isNotEmpty)) {
      rows.add(values);
    }
  }
  return rows;
}

List<String> _readXlsxSharedStrings(Archive archive) {
  final file = archive.findFile('xl/sharedStrings.xml');
  if (file == null) {
    return const [];
  }
  final document = XmlDocument.parse(utf8.decode(file.content));
  final values = <String>[];
  for (final item in document.findAllElements('si')) {
    final text = item
        .findAllElements('t')
        .map((node) => node.innerText)
        .join();
    values.add(text.trim());
  }
  return values;
}

String? _readFirstXlsxWorksheetXml(Archive archive) {
  ArchiveFile? sheetFile;
  for (final file in archive.files) {
    final name = file.name;
    if (name.startsWith('xl/worksheets/sheet') && name.endsWith('.xml')) {
      sheetFile = file;
      break;
    }
  }
  if (sheetFile == null) {
    return null;
  }
  return utf8.decode(sheetFile.content);
}

int _columnIndexFromCellRef(String ref) {
  final match = RegExp(r'^([A-Za-z]+)').firstMatch(ref);
  if (match == null) {
    return 0;
  }
  final letters = match.group(1)!.toUpperCase();
  var index = 0;
  for (var i = 0; i < letters.length; i++) {
    index = index * 26 + (letters.codeUnitAt(i) - 64);
  }
  return index - 1;
}

String _readXlsxCellValue(XmlElement cell, List<String> sharedStrings) {
  final type = cell.getAttribute('t');
  if (type == 'inlineStr') {
    return cell
        .findAllElements('t')
        .map((node) => node.innerText)
        .join()
        .trim();
  }

  final rawValue = cell.findElements('v').firstOrNull?.innerText ?? '';
  if (type == 's') {
    final index = int.tryParse(rawValue);
    if (index != null && index >= 0 && index < sharedStrings.length) {
      return sharedStrings[index];
    }
    return '';
  }
  return rawValue.trim();
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

bool? _parseActive(String raw) {
  final value = raw.trim().toLowerCase();
  if (value.isEmpty) {
    return null;
  }
  if ({'yes', 'y', 'true', '1', 'active'}.contains(value)) {
    return true;
  }
  if ({'no', 'n', 'false', '0', 'inactive'}.contains(value)) {
    return false;
  }
  return null;
}

double? _parsePrice(String raw) {
  final cleaned = raw
      .trim()
      .replaceAll(RegExp(r'[^\d.,-]'), '')
      .replaceAll(',', '');
  if (cleaned.isEmpty) {
    return null;
  }
  return double.tryParse(cleaned);
}

bool _looksLikeHeaderRow(List<String> row) {
  final normalized = row.map((c) => c.trim().toLowerCase()).toList();
  return normalized.any(_nameHeaders.contains) ||
      normalized.any(_skuHeaders.contains) ||
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

String _fallbackSku(String name, int lineNumber) {
  final slug = name
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isEmpty) {
    return 'IMPORT-$lineNumber';
  }
  return slug.length > 40 ? slug.substring(0, 40) : slug;
}

ProductImportParseResult parseProductImportFile({
  required Uint8List bytes,
  required String filename,
}) {
  final rawRows = parseSpreadsheetRows(bytes: bytes, filename: filename);
  if (rawRows.isEmpty) {
    throw ProductImportException('The file is empty.');
  }

  var dataRows = rawRows;
  Map<String, int>? headers;
  if (_looksLikeHeaderRow(rawRows.first)) {
    headers = _headerIndex(rawRows.first);
    dataRows = rawRows.skip(1).toList();
  }

  final nameIndex = headers != null
      ? _columnIndex(headers, _nameHeaders)
      : (rawRows.first.length > 0 ? 0 : null);
  final skuIndex = headers != null ? _columnIndex(headers, _skuHeaders) : 1;
  final priceIndex = headers != null ? _columnIndex(headers, _priceHeaders) : 2;
  final categoryIndex =
      headers != null ? _columnIndex(headers, _categoryHeaders) : 3;
  final activeIndex =
      headers != null ? _columnIndex(headers, _activeHeaders) : null;
  final imageIndex =
      headers != null ? _columnIndex(headers, _imageHeaders) : null;

  if (nameIndex == null || priceIndex == null) {
    throw ProductImportException(
      'Missing required columns. Include at least Name and Price '
      '(header row recommended).',
    );
  }

  final parsed = <ProductImportRow>[];
  var lineNumber = headers != null ? 2 : 1;
  for (final row in dataRows) {
    final name = _cell(row, nameIndex);
    final skuRaw = _cell(row, skuIndex);
    final priceRaw = _cell(row, priceIndex);
    final categoryRaw = _cell(row, categoryIndex);
    final activeRaw = _cell(row, activeIndex);
    final imageRaw = _cell(row, imageIndex);

    String? error;
    final price = _parsePrice(priceRaw);
    if (name.isEmpty) {
      error = 'Product name is required';
    } else if (price == null || price <= 0) {
      error = 'Valid price is required';
    }

    final active = _parseActive(activeRaw);
    parsed.add(
      ProductImportRow(
        lineNumber: lineNumber,
        name: name,
        sku: skuRaw.isNotEmpty ? skuRaw : _fallbackSku(name, lineNumber),
        price: price ?? 0,
        category: categoryRaw.isNotEmpty
            ? normalizeProductCategoryName(categoryRaw)
            : null,
        isActive: active ?? true,
        imageUrl: imageRaw.isNotEmpty ? imageRaw : null,
        error: error,
      ),
    );
    lineNumber++;
  }

  if (parsed.isEmpty) {
    throw ProductImportException('No product rows found in the file.');
  }

  return ProductImportParseResult(
    rows: parsed,
    fileLabel: filename,
  );
}

Future<ProductImportWriteResult> writeImportedProducts(
  List<ProductImportRow> rows,
) async {
  final validRows = rows.where((row) => row.isValid).toList();
  if (validRows.isEmpty) {
    return const ProductImportWriteResult(
      created: 0,
      skippedDuplicates: 0,
      failed: 0,
      messages: ['No valid rows to import.'],
    );
  }

  final existing = await queryTenantProductRecordOnce(limit: 2000);
  final existingSkus = existing
      .map((product) => product.sku.trim().toLowerCase())
      .where((sku) => sku.isNotEmpty)
      .toSet();

  var created = 0;
  var skippedDuplicates = 0;
  var failed = 0;
  final messages = <String>[];

  for (final row in validRows) {
    final skuKey = row.sku.trim().toLowerCase();
    if (existingSkus.contains(skuKey)) {
      skippedDuplicates++;
      messages.add('Line ${row.lineNumber}: skipped duplicate SKU ${row.sku}');
      continue;
    }

    try {
      await ProductRecord.collection.doc().set(
            createTenantProductRecordData(
              name: row.name,
              sku: row.sku,
              price: row.price,
              category: row.category,
              isActive: row.isActive,
              image: row.imageUrl,
            ),
          );
      existingSkus.add(skuKey);
      created++;
    } catch (error) {
      failed++;
      messages.add('Line ${row.lineNumber}: $error');
    }
  }

  return ProductImportWriteResult(
    created: created,
    skippedDuplicates: skippedDuplicates,
    failed: failed,
    messages: messages,
  );
}

class ProductImportException implements Exception {
  ProductImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
