import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/create_order_service.dart';
import '/backend/material_category_helpers.dart';
import '/backend/schema/material_record.dart';
import '/backend/tenant_query_helpers.dart';

const defaultMaterialUnits = [
  'stem',
  'bundle',
  'pcs',
  'sheet',
  'roll',
  'bag',
  'box',
  'meter',
];

String normalizeMaterialName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

String normalizeMaterialUnit(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return 'pcs';
  }
  return trimmed;
}

Future<String?> saveMaterialRecord({
  required DocumentReference ref,
  required String name,
  required String unit,
  String? sku,
  double? cost,
  required bool isActive,
  String? category,
  MaterialRecord? existing,
}) async {
  final trimmedName = normalizeMaterialName(name);
  if (trimmedName.isEmpty) {
    return 'Material name is required.';
  }

  final normalizedCategory = normalizeMaterialCategoryName(category ?? '');
  final payload = createTenantMaterialRecordData(
    name: trimmedName,
    unit: normalizeMaterialUnit(unit),
    sku: sku?.trim(),
    cost: cost,
    isActive: isActive,
    category: normalizedCategory.isEmpty ? null : normalizedCategory,
  );

  try {
    if (existing == null) {
      await ref.set(payload);
    } else {
      await ref.update(payload);
    }
    return null;
  } catch (error) {
    return describeFirestoreError(error);
  }
}

Future<String?> deleteMaterialRecord(MaterialRecord material) async {
  try {
    await material.reference.delete();
    return null;
  } catch (error) {
    return describeFirestoreError(error);
  }
}

String materialDisplayLabel(MaterialRecord material) {
  final unit = material.unit.trim();
  if (unit.isEmpty) {
    return material.name;
  }
  return '${material.name} ($unit)';
}

String normalizeMaterialSearchText(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

List<MaterialRecord> filterMaterialsBySearchQuery(
  List<MaterialRecord> materials,
  String input,
) {
  final query = normalizeMaterialSearchText(input);
  if (query.isEmpty) {
    return materials;
  }
  return materials.where((material) {
    final haystack = [
      material.name,
      material.sku,
      material.category,
      material.unit,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }).toList();
}

List<MaterialRecord> applyMaterialSelectionFilters({
  required List<MaterialRecord> materials,
  required String searchQuery,
  String? category,
}) {
  final searched = filterMaterialsBySearchQuery(materials, searchQuery);
  final filtered = category == null || category.isEmpty
      ? searched
      : filterMaterialsByCategory(searched, category);
  return [...filtered]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

const uncategorizedMaterialCategoryLabel = 'Uncategorized';

List<String> materialCategoryOptionsForMaterials(
  List<String> managedCategories,
  List<MaterialRecord> materials,
) {
  final options = normalizeMaterialCategoryList([
    ...managedCategories,
    ...materials.map((material) => material.category),
  ]);
  if (materials.any((material) => material.category.trim().isEmpty)) {
    return [...options, uncategorizedMaterialCategoryLabel];
  }
  return options;
}

List<MaterialRecord> filterMaterialsByCategory(
  List<MaterialRecord> materials,
  String category,
) {
  if (category == uncategorizedMaterialCategoryLabel) {
    return materials
        .where((material) => material.category.trim().isEmpty)
        .toList();
  }
  return materials
      .where(
        (material) =>
            material.category.toLowerCase() == category.toLowerCase(),
      )
      .toList();
}
