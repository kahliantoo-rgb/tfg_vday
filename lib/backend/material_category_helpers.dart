import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/create_order_service.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Generic fallback for companies without a saved material category list.
const defaultMaterialCategories = [
  'Fresh Flowers',
  'Foliage',
  'Packaging',
  'Hard Goods',
  'Ad-Hoc',
];

/// The Flower Guy Pte Ltd — canonical production company.
const theFlowerGuyMaterialCategories = [
  'Fresh Flowers',
  'Foliage',
  'Packaging',
  'Ribbon & Accessories',
  'Hard Goods',
  'Ad-Hoc',
];

List<String> defaultMaterialCategoriesForCompanyId(String companyId) {
  if (canonicalCompanyId(companyId) == kCanonicalCompanyId) {
    return List<String>.from(theFlowerGuyMaterialCategories);
  }
  return List<String>.from(defaultMaterialCategories);
}

String normalizeMaterialCategoryName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

List<String> normalizeMaterialCategoryList(Iterable<String> values) {
  final seen = <String>{};
  final normalized = <String>[];
  for (final value in values) {
    final name = normalizeMaterialCategoryName(value);
    if (name.isEmpty) {
      continue;
    }
    final key = name.toLowerCase();
    if (seen.add(key)) {
      normalized.add(name);
    }
  }
  normalized.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return normalized;
}

List<String> parseMaterialCategoriesFromData(Map<String, dynamic>? data) {
  if (data == null) {
    return const [];
  }
  final raw = data['categories'];
  if (raw is! List) {
    return const [];
  }
  return normalizeMaterialCategoryList(raw.whereType<String>());
}

DocumentReference? tenantMaterialCategoriesCompanyRef() {
  final ref = TenantContext.instance.writeCompanyRef ??
      TenantContext.instance.activeCompanyRef;
  if (ref == null) {
    return null;
  }
  return canonicalCompanyRef(ref);
}

DocumentReference? tenantMaterialCategoriesDocRef() {
  final companyRef = tenantMaterialCategoriesCompanyRef();
  if (companyRef == null) {
    return null;
  }
  return FirebaseFirestore.instance
      .collection('material_categories')
      .doc(canonicalCompanyId(companyRef.id));
}

Stream<List<String>> streamTenantMaterialCategories() {
  final docRef = tenantMaterialCategoriesDocRef();
  if (docRef == null) {
    return Stream.value(const <String>[]);
  }
  return docRef.snapshots().map(
        (snapshot) => parseMaterialCategoriesFromData(
          snapshot.data() as Map<String, dynamic>?,
        ),
      );
}

Future<List<String>> collectCategoriesFromCompanyMaterials() async {
  final companyRef = tenantMaterialCategoriesCompanyRef();
  if (companyRef == null) {
    return const [];
  }
  final targetCompanyId = canonicalCompanyId(companyRef.id);
  final materials = await queryTenantMaterialRecordOnce(limit: 500);
  return materials
      .where(
        (material) =>
            canonicalCompanyId(material.companyRef?.id) == targetCompanyId,
      )
      .map((material) => material.category)
      .where((category) => category.trim().isNotEmpty)
      .toList();
}

Future<List<String>> resolveInitialMaterialCategories() async {
  final companyRef = tenantMaterialCategoriesCompanyRef();
  if (companyRef == null) {
    return const [];
  }
  return normalizeMaterialCategoryList([
    ...defaultMaterialCategoriesForCompanyId(companyRef.id),
    ...await collectCategoriesFromCompanyMaterials(),
  ]);
}

Future<void> ensureTenantMaterialCategoriesInitialized() async {
  final docRef = tenantMaterialCategoriesDocRef();
  final companyRef = tenantMaterialCategoriesCompanyRef();
  if (docRef == null || companyRef == null) {
    return;
  }

  final target = await resolveInitialMaterialCategories();
  if (target.isEmpty) {
    return;
  }

  final snapshot = await docRef.get();
  if (!snapshot.exists) {
    await saveTenantMaterialCategories(target);
    return;
  }

  final existing = parseMaterialCategoriesFromData(
    snapshot.data() as Map<String, dynamic>?,
  );
  final merged = normalizeMaterialCategoryList([...existing, ...target]);
  if (merged.length != existing.length) {
    await saveTenantMaterialCategories(merged);
  }
}

Future<List<String>> loadTenantMaterialCategoriesOnce() async {
  final docRef = tenantMaterialCategoriesDocRef();
  if (docRef == null) {
    return const [];
  }
  final snapshot = await docRef.get();
  return parseMaterialCategoriesFromData(
    snapshot.data() as Map<String, dynamic>?,
  );
}

Future<List<String>> loadManagedMaterialCategoriesWithFallback() async {
  try {
    await ensureTenantMaterialCategoriesInitialized();
    final stored = await loadTenantMaterialCategoriesOnce();
    if (stored.isNotEmpty) {
      return stored;
    }
  } catch (_) {
    // Fall back to defaults + material text fields below.
  }
  return resolveInitialMaterialCategories();
}

Future<void> saveTenantMaterialCategories(List<String> categories) async {
  final docRef = tenantMaterialCategoriesDocRef();
  final companyRef = tenantMaterialCategoriesCompanyRef();
  if (docRef == null || companyRef == null) {
    throw StateError('No company selected for category save.');
  }
  final rulesCompanyRef =
      TenantContext.instance.rulesMatchedCompanyRef ?? companyRef;
  await docRef.set(
    {
      'companyRef': rulesCompanyRef,
      'categories': normalizeMaterialCategoryList(categories),
      'updated_time': getCurrentTimestamp,
    },
    SetOptions(merge: true),
  );
}

Future<String?> addTenantMaterialCategory(String name) async {
  final trimmed = normalizeMaterialCategoryName(name);
  if (trimmed.isEmpty) {
    return 'Category name is required.';
  }
  try {
    final current = await loadManagedMaterialCategoriesWithFallback();
    final exists = current.any(
      (category) => category.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      return 'Category already exists.';
    }
    await saveTenantMaterialCategories([...current, trimmed]);
    return null;
  } catch (error) {
    return describeFirestoreError(error);
  }
}

Future<int> countTenantMaterialsInCategory(String category) async {
  final materials = await queryTenantMaterialRecordOnce();
  return materials
      .where(
        (material) =>
            material.category.toLowerCase() == category.toLowerCase(),
      )
      .length;
}

Future<String?> removeTenantMaterialCategory(String category) async {
  try {
    final current = await loadManagedMaterialCategoriesWithFallback();
    final updated = current
        .where(
          (value) => value.toLowerCase() != category.toLowerCase(),
        )
        .toList();
    if (updated.length == current.length) {
      return 'Category not found.';
    }
    await saveTenantMaterialCategories(updated);
    return null;
  } catch (error) {
    return describeFirestoreError(error);
  }
}

List<String> mergeMaterialCategoryOptions({
  required List<String> managedCategories,
  Iterable<String> materialCategories = const [],
}) {
  return normalizeMaterialCategoryList([
    ...managedCategories,
    ...materialCategories,
  ]);
}

String? tenantMaterialCategoriesCompanyLabel() {
  final company = TenantContext.instance.activeCompany;
  if (company != null && company.companyName.isNotEmpty) {
    return company.companyName;
  }
  final ref = tenantMaterialCategoriesCompanyRef();
  if (ref != null) {
    return ref.id;
  }
  return null;
}

bool ensureSingleCompanyForMaterialCatalogWrite(BuildContext context) {
  if (!ensureActiveCompanyForWrite(context)) {
    return false;
  }
  if (TenantContext.instance.isViewingAllCompanies) {
    final label = tenantMaterialCategoriesCompanyLabel();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          label != null
              ? 'Managing material categories for $label only.'
              : 'Managing material categories for the selected company only.',
        ),
      ),
    );
  }
  return true;
}

class _ManageMaterialCategoriesPanel extends StatefulWidget {
  const _ManageMaterialCategoriesPanel({
    required this.companyLabel,
    required this.onSavingChanged,
  });

  final String? companyLabel;
  final ValueChanged<bool> onSavingChanged;

  @override
  State<_ManageMaterialCategoriesPanel> createState() =>
      _ManageMaterialCategoriesPanelState();
}

class _ManageMaterialCategoriesPanelState
    extends State<_ManageMaterialCategoriesPanel> {
  final _addController = TextEditingController();
  List<String> _categories = const [];
  bool _loading = true;
  String? _syncError;
  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _reloadCategories();
    _subscribeToCategories();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _addController.dispose();
    super.dispose();
  }

  void _subscribeToCategories() {
    final docRef = tenantMaterialCategoriesDocRef();
    if (docRef == null) {
      return;
    }
    _subscription = docRef.snapshots().listen(
      (snapshot) {
        if (!mounted) {
          return;
        }
        setState(() {
          _categories = parseMaterialCategoriesFromData(
            snapshot.data() as Map<String, dynamic>?,
          );
          _syncError = null;
          _loading = false;
        });
      },
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          if (_categories.isEmpty) {
            _syncError = describeFirestoreError(error);
          }
          _loading = false;
        });
      },
    );
  }

  Future<void> _reloadCategories() async {
    setState(() {
      _loading = true;
      _syncError = null;
    });
    try {
      final categories = await loadManagedMaterialCategoriesWithFallback();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _syncError = describeFirestoreError(error);
        _loading = false;
      });
    }
  }

  Future<void> _addCategory() async {
    widget.onSavingChanged(true);
    final error = await addTenantMaterialCategory(_addController.text);
    if (!mounted) {
      return;
    }
    if (error == null) {
      _addController.clear();
      await _reloadCategories();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
    widget.onSavingChanged(false);
  }

  Future<void> _deleteCategory(String category) async {
    final materialCount = await countTenantMaterialsInCategory(category);
    if (!mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmContext) {
        return AlertDialog(
          title: const Text('Delete category?'),
          content: Text(
            materialCount > 0
                ? '$materialCount material(s) still use "$category". '
                    'They will keep this category, but it will be removed from the picker.'
                : 'Remove "$category" from the category list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(confirmContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(confirmContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    widget.onSavingChanged(true);
    final error = await removeTenantMaterialCategory(category);
    if (!mounted) {
      return;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      await _reloadCategories();
    }
    widget.onSavingChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = !_loading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.companyLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Company: ${widget.companyLabel}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        if (_syncError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _syncError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        TextField(
          controller: _addController,
          enabled: canEdit,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'New category',
            hintText: 'e.g. Fresh Flowers',
            border: OutlineInputBorder(),
          ),
          onSubmitted: canEdit ? (_) => _addCategory() : null,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: canEdit ? _addCategory : null,
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_categories.isEmpty)
          const Text('No categories yet. Add one above.')
        else
          SizedBox(
            height: 280,
            child: ListView.separated(
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(category),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: canEdit ? () => _deleteCategory(category) : null,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

Future<void> showManageMaterialCategoriesDialog(BuildContext context) async {
  if (!ensureSingleCompanyForMaterialCatalogWrite(context)) {
    return;
  }

  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Manage Material Categories'),
            content: SizedBox(
              width: double.maxFinite,
              child: _ManageMaterialCategoriesPanel(
                companyLabel: tenantMaterialCategoriesCompanyLabel(),
                onSavingChanged: (value) {
                  setDialogState(() => saving = value);
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    },
  );
}
