import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/create_order_service.dart';
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
  MaterialRecord? existing,
}) async {
  final trimmedName = normalizeMaterialName(name);
  if (trimmedName.isEmpty) {
    return 'Material name is required.';
  }

  final payload = createTenantMaterialRecordData(
    name: trimmedName,
    unit: normalizeMaterialUnit(unit),
    sku: sku?.trim(),
    cost: cost,
    isActive: isActive,
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
