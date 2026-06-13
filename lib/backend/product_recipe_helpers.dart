import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/material_record.dart';
import '/backend/schema/product_record.dart';

class ProductRecipeLine {
  const ProductRecipeLine({
    this.materialRef,
    this.materialName = '',
    this.qty = 1,
    this.unit = '',
  });

  final DocumentReference? materialRef;
  final String materialName;
  final double qty;
  final String unit;

  ProductRecipeLine copyWith({
    DocumentReference? materialRef,
    String? materialName,
    double? qty,
    String? unit,
  }) {
    return ProductRecipeLine(
      materialRef: materialRef ?? this.materialRef,
      materialName: materialName ?? this.materialName,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (materialRef != null) 'materialRef': materialRef,
      'materialName': materialName,
      'qty': qty,
      'unit': unit,
    };
  }

  static ProductRecipeLine fromMap(Map<String, dynamic> data) {
    return ProductRecipeLine(
      materialRef: data['materialRef'] as DocumentReference?,
      materialName: data['materialName'] as String? ?? '',
      qty: (data['qty'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] as String? ?? '',
    );
  }
}

List<ProductRecipeLine> parseProductRecipeLines(ProductRecord product) {
  return product.recipeLines
      .map(ProductRecipeLine.fromMap)
      .where((line) => line.materialName.isNotEmpty || line.materialRef != null)
      .toList();
}

List<ProductRecipeLine> parseProductRecipeLinesFromMaps(
  Iterable<Map<String, dynamic>> lines,
) {
  return lines
      .map(ProductRecipeLine.fromMap)
      .where((line) => line.materialName.isNotEmpty || line.materialRef != null)
      .toList();
}

List<Map<String, dynamic>> productRecipeLinesToFirestore(
  Iterable<ProductRecipeLine> lines,
) {
  return lines
      .where(
        (line) =>
            line.materialRef != null &&
            line.qty > 0 &&
            line.materialName.isNotEmpty,
      )
      .map((line) => line.toMap())
      .toList();
}

ProductRecipeLine productRecipeLineFromMaterial(
  MaterialRecord material, {
  double qty = 1,
}) {
  return ProductRecipeLine(
    materialRef: material.reference,
    materialName: material.name,
    qty: qty,
    unit: material.unit,
  );
}

String formatProductRecipeLine(ProductRecipeLine line) {
  final qtyLabel = line.qty == line.qty.roundToDouble()
      ? line.qty.toInt().toString()
      : line.qty.toStringAsFixed(2);
  final unit = line.unit.trim();
  if (unit.isEmpty) {
    return '$qtyLabel × ${line.materialName}';
  }
  return '$qtyLabel $unit ${line.materialName}';
}
