import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/product_import_helpers.dart';
import 'package:xml/xml.dart';

void main() {
  group('parseProductImportFile', () {
    test('parses csv with header row', () {
      const csv = '''
Name,SKU,Price,Category,Active
Rose Bouquet,RB-01,88.50,Hand Bouquet,yes
Wreath Classic,WR-02,120,Wreath,true
''';
      final result = parseProductImportFile(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'products.csv',
      );

      expect(result.rows, hasLength(2));
      expect(result.rows.first.name, 'Rose Bouquet');
      expect(result.rows.first.sku, 'RB-01');
      expect(result.rows.first.price, 88.5);
      expect(result.rows.first.category, 'Hand Bouquet');
      expect(result.rows.first.isActive, isTrue);
      expect(result.validCount, 2);
    });

    test('auto-generates sku when missing', () {
      const csv = 'Name,Price\nSunflower Box,45\n';
      final result = parseProductImportFile(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'products.csv',
      );

      expect(result.rows.single.sku, 'SUNFLOWER-BOX');
      expect(result.rows.single.isValid, isTrue);
    });

    test('marks invalid rows when price missing', () {
      const csv = 'Name,Price\nBroken Product,\n';
      final result = parseProductImportFile(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'products.csv',
      );

      expect(result.rows.single.error, isNotNull);
      expect(result.validCount, 0);
      expect(result.errorCount, 1);
    });

    test('parses xlsx worksheet', () {
      final bytes = _buildSampleXlsxBytes();
      final result = parseProductImportFile(
        bytes: bytes,
        filename: 'products.xlsx',
      );

      expect(result.rows, hasLength(2));
      expect(result.rows.first.name, 'Excel Rose');
      expect(result.rows.first.sku, 'EX-01');
      expect(result.rows.first.price, 99);
      expect(result.rows.last.category, 'Wreath');
      expect(result.validCount, 2);
    });
  });
}

Uint8List _buildSampleXlsxBytes() {
  final sharedStringsXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="10" uniqueCount="10">
  <si><t>Name</t></si>
  <si><t>SKU</t></si>
  <si><t>Price</t></si>
  <si><t>Category</t></si>
  <si><t>Excel Rose</t></si>
  <si><t>EX-01</t></si>
  <si><t>Hand Bouquet</t></si>
  <si><t>Excel Wreath</t></si>
  <si><t>WR-EX</t></si>
  <si><t>Wreath</t></si>
</sst>
''';

  final sheetXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
    <row r="1">
      <c r="A1" t="s"><v>0</v></c>
      <c r="B1" t="s"><v>1</v></c>
      <c r="C1" t="s"><v>2</v></c>
      <c r="D1" t="s"><v>3</v></c>
    </row>
    <row r="2">
      <c r="A2" t="s"><v>4</v></c>
      <c r="B2" t="s"><v>5</v></c>
      <c r="C2"><v>99</v></c>
      <c r="D2" t="s"><v>6</v></c>
    </row>
    <row r="3">
      <c r="A3" t="s"><v>7</v></c>
      <c r="B3" t="s"><v>8</v></c>
      <c r="C3"><v>150</v></c>
      <c r="D3" t="s"><v>9</v></c>
    </row>
  </sheetData>
</worksheet>
''';

  final archive = Archive()
    ..addFile(
      ArchiveFile(
        '[Content_Types].xml',
        0,
        Uint8List(0),
      ),
    )
    ..addFile(
      ArchiveFile(
        'xl/sharedStrings.xml',
        sharedStringsXml.length,
        utf8.encode(sharedStringsXml),
      ),
    )
    ..addFile(
      ArchiveFile(
        'xl/worksheets/sheet1.xml',
        sheetXml.length,
        utf8.encode(sheetXml),
      ),
    );

  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}
