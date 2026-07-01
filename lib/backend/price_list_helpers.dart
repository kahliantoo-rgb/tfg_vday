import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';
import '/backend/schema/product_record.dart';
import '/backend/schema/util/firestore_util.dart';
import '/backend/tenant_context.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PriceListLine {
  const PriceListLine({
    required this.sku,
    required this.price,
    this.productRef,
    this.productName = '',
  });

  final String sku;
  final double price;
  final DocumentReference? productRef;
  final String productName;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'sku': sku,
      'price': price,
      if (productRef != null) 'productRef': productRef,
      if (productName.isNotEmpty) 'productName': productName,
    };
  }

  static PriceListLine fromMap(Map<String, dynamic> data) {
    return PriceListLine(
      sku: data['sku'] as String? ?? '',
      price: castToType<double>(data['price']) ?? 0,
      productRef: data['productRef'] as DocumentReference?,
      productName: data['productName'] as String? ?? '',
    );
  }
}

String normalizePriceListSku(String sku) =>
    sku.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

List<PriceListLine> parsePriceListLines(PriceListsRecord record) {
  return record.priceLines
      .map(PriceListLine.fromMap)
      .where((line) => line.sku.isNotEmpty && line.price > 0)
      .toList();
}

double? lookupContractPrice({
  required PriceListsRecord priceList,
  required ProductRecord product,
}) {
  final lines = parsePriceListLines(priceList);
  if (lines.isEmpty) {
    return null;
  }

  final productSku = normalizePriceListSku(product.sku);
  if (productSku.isNotEmpty) {
    for (final line in lines) {
      if (normalizePriceListSku(line.sku) == productSku) {
        return line.price;
      }
    }
  }

  final productPath = product.reference.path;
  for (final line in lines) {
    if (line.productRef?.path == productPath) {
      return line.price;
    }
  }

  return null;
}

Future<double> resolveProductUnitPriceForOrder({
  required DocumentReference orderRef,
  required ProductRecord product,
}) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  if (order.customerRef == null) {
    return product.price;
  }

  final customer = await CustomersRecord.getDocumentOnce(order.customerRef!);
  if (!customer.hasPriceListRef()) {
    return product.price;
  }

  final priceList =
      await PriceListsRecord.getDocumentOnce(customer.priceListRef!);
  return lookupContractPrice(priceList: priceList, product: product) ??
      product.price;
}

Future<DocumentReference> createPriceList({
  required String name,
}) async {
  final companyRef = TenantContext.instance.rulesMatchedCompanyRef;
  if (companyRef == null) {
    throw StateError('No company selected.');
  }
  final ref = PriceListsRecord.collection.doc();
  await ref.set(
    createPriceListsRecordData(
      name: name.trim(),
      companyRef: companyRef,
      priceLines: const [],
      createdTime: getCurrentTimestamp,
      updatedTime: getCurrentTimestamp,
    ),
  );
  return ref;
}

Future<void> updatePriceListName({
  required DocumentReference priceListRef,
  required String name,
}) async {
  await priceListRef.update(
    createPriceListsRecordData(
      name: name.trim(),
      updatedTime: getCurrentTimestamp,
    ),
  );
}

List<PriceListLine> mergePriceListLinesBySku({
  required List<PriceListLine> existing,
  required List<PriceListLine> incoming,
}) {
  final bySku = <String, PriceListLine>{
    for (final line in existing)
      if (line.sku.isNotEmpty) normalizePriceListSku(line.sku): line,
  };
  for (final line in incoming) {
    final key = normalizePriceListSku(line.sku);
    if (key.isEmpty) {
      continue;
    }
    bySku[key] = line;
  }
  final merged = bySku.values.toList()
    ..sort((a, b) => a.sku.compareTo(b.sku));
  return merged;
}

Future<void> savePriceListLines({
  required DocumentReference priceListRef,
  required List<PriceListLine> lines,
}) async {
  await priceListRef.update(
    createPriceListsRecordData(
      priceLines: lines.map((line) => line.toFirestoreMap()).toList(),
      updatedTime: getCurrentTimestamp,
    ),
  );
}

Future<void> upsertPriceListLines({
  required DocumentReference priceListRef,
  required List<PriceListLine> incoming,
}) async {
  final record = await PriceListsRecord.getDocumentOnce(priceListRef);
  final merged = mergePriceListLinesBySku(
    existing: parsePriceListLines(record),
    incoming: incoming,
  );
  await savePriceListLines(priceListRef: priceListRef, lines: merged);
}

Map<String, ProductRecord> buildProductCatalogBySku(
  Iterable<ProductRecord> products,
) {
  final map = <String, ProductRecord>{};
  for (final product in products) {
    final key = normalizePriceListSku(product.sku);
    if (key.isEmpty) {
      continue;
    }
    map.putIfAbsent(key, () => product);
  }
  return map;
}

List<PriceListLine> enrichPriceListLinesFromCatalog({
  required List<PriceListLine> lines,
  required Map<String, ProductRecord> productsBySku,
}) {
  return lines.map((line) {
    final product = productsBySku[normalizePriceListSku(line.sku)];
    if (product == null) {
      return line;
    }
    return PriceListLine(
      sku: product.sku.isNotEmpty ? product.sku : line.sku,
      price: line.price,
      productRef: product.reference,
      productName: product.name.isNotEmpty ? product.name : line.productName,
    );
  }).toList();
}

String priceListLabel(PriceListsRecord record) {
  final name = record.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  return record.reference.id;
}
