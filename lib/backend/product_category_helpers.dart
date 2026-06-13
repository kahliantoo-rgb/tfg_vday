import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/create_order_service.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Generic fallback for companies without a saved category list.
const defaultProductCategories = [
  'Hand Bouquet',
  'Wreath',
  'Opening Stand',
  'Table arrangement',
  'AdHoc',
];

/// The Flower Guy Pte Ltd — canonical production company.
const theFlowerGuyProductCategories = [
  'Funeral',
  'Hand Bouquet',
  'Wreath',
  'Opening Stand',
  'Wedding',
  'Ad-Hoc',
];

List<String> defaultCategoriesForCompanyId(String companyId) {
  if (canonicalCompanyId(companyId) == kCanonicalCompanyId) {
    return List<String>.from(theFlowerGuyProductCategories);
  }
  return List<String>.from(defaultProductCategories);
}

String normalizeProductCategoryName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

List<String> normalizeProductCategoryList(Iterable<String> values) {
  final seen = <String>{};
  final normalized = <String>[];
  for (final value in values) {
    final name = normalizeProductCategoryName(value);
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

List<String> parseProductCategoriesFromData(Map<String, dynamic>? data) {
  if (data == null) {
    return const [];
  }
  final raw = data['categories'];
  if (raw is! List) {
    return const [];
  }
  return normalizeProductCategoryList(raw.whereType<String>());
}

DocumentReference? tenantProductCategoriesCompanyRef() {
  final ref = TenantContext.instance.writeCompanyRef ??
      TenantContext.instance.activeCompanyRef;
  if (ref == null) {
    return null;
  }
  return canonicalCompanyRef(ref);
}

DocumentReference? tenantProductCategoriesDocRef() {
  final companyRef = tenantProductCategoriesCompanyRef();
  if (companyRef == null) {
    return null;
  }
  return FirebaseFirestore.instance
      .collection('product_categories')
      .doc(canonicalCompanyId(companyRef.id));
}

Stream<List<String>> streamTenantProductCategories() {
  final docRef = tenantProductCategoriesDocRef();
  if (docRef == null) {
    return Stream.value(const <String>[]);
  }
  return docRef.snapshots().map(
        (snapshot) => parseProductCategoriesFromData(
          snapshot.data() as Map<String, dynamic>?,
        ),
      );
}

Future<List<String>> collectCategoriesFromCompanyProducts() async {
  final companyRef = tenantProductCategoriesCompanyRef();
  if (companyRef == null) {
    return const [];
  }
  final targetCompanyId = canonicalCompanyId(companyRef.id);
  final products = await queryTenantProductRecordOnce(limit: 500);
  return products
      .where(
        (product) =>
            canonicalCompanyId(product.companyRef?.id) == targetCompanyId,
      )
      .map((product) => product.category)
      .where((category) => category.trim().isNotEmpty)
      .toList();
}

Future<List<String>> resolveInitialCompanyCategories() async {
  final companyRef = tenantProductCategoriesCompanyRef();
  if (companyRef == null) {
    return const [];
  }
  return normalizeProductCategoryList([
    ...defaultCategoriesForCompanyId(companyRef.id),
    ...await collectCategoriesFromCompanyProducts(),
  ]);
}

Future<void> ensureTenantProductCategoriesInitialized() async {
  final docRef = tenantProductCategoriesDocRef();
  final companyRef = tenantProductCategoriesCompanyRef();
  if (docRef == null || companyRef == null) {
    return;
  }

  final target = await resolveInitialCompanyCategories();
  if (target.isEmpty) {
    return;
  }

  final snapshot = await docRef.get();
  if (!snapshot.exists) {
    await saveTenantProductCategories(target);
    return;
  }

  final existing = parseProductCategoriesFromData(
    snapshot.data() as Map<String, dynamic>?,
  );
  final merged = normalizeProductCategoryList([...existing, ...target]);
  if (merged.length != existing.length) {
    await saveTenantProductCategories(merged);
  }
}

Future<List<String>> loadTenantProductCategoriesOnce() async {
  final docRef = tenantProductCategoriesDocRef();
  if (docRef == null) {
    return const [];
  }
  final snapshot = await docRef.get();
  return parseProductCategoriesFromData(
    snapshot.data() as Map<String, dynamic>?,
  );
}

Future<List<String>> loadManagedProductCategoriesWithFallback() async {
  try {
    await ensureTenantProductCategoriesInitialized();
    final stored = await loadTenantProductCategoriesOnce();
    if (stored.isNotEmpty) {
      return stored;
    }
  } catch (_) {
    // Fall back to defaults + product text fields below.
  }
  return resolveInitialCompanyCategories();
}

Future<void> saveTenantProductCategories(List<String> categories) async {
  final docRef = tenantProductCategoriesDocRef();
  final companyRef = tenantProductCategoriesCompanyRef();
  if (docRef == null || companyRef == null) {
    throw StateError('No company selected for category save.');
  }
  // Match Firestore rules (authUserCompanyRef), not canonical doc id alone.
  final rulesCompanyRef =
      TenantContext.instance.rulesMatchedCompanyRef ?? companyRef;
  await docRef.set(
    {
      'companyRef': rulesCompanyRef,
      'categories': normalizeProductCategoryList(categories),
      'updated_time': getCurrentTimestamp,
    },
    SetOptions(merge: true),
  );
}

Future<String?> addTenantProductCategory(String name) async {
  final trimmed = normalizeProductCategoryName(name);
  if (trimmed.isEmpty) {
    return 'Category name is required.';
  }
  try {
    final current = await loadManagedProductCategoriesWithFallback();
    final exists = current.any(
      (category) => category.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      return 'Category already exists.';
    }
    await saveTenantProductCategories([...current, trimmed]);
    return null;
  } catch (error) {
    return describeFirestoreError(error);
  }
}

Future<int> countTenantProductsInCategory(String category) async {
  final products = await queryTenantProductRecordOnce();
  return products
      .where(
        (product) =>
            product.category.toLowerCase() == category.toLowerCase(),
      )
      .length;
}

Future<String?> removeTenantProductCategory(String category) async {
  try {
    final current = await loadManagedProductCategoriesWithFallback();
    final updated = current
        .where(
          (value) => value.toLowerCase() != category.toLowerCase(),
        )
        .toList();
    if (updated.length == current.length) {
      return 'Category not found.';
    }
    await saveTenantProductCategories(updated);
    return null;
  } catch (error) {
    return describeFirestoreError(error);
  }
}

List<String> mergeProductCategoryOptions({
  required List<String> managedCategories,
  Iterable<String> productCategories = const [],
}) {
  return normalizeProductCategoryList([
    ...managedCategories,
    ...productCategories,
  ]);
}

String? tenantProductCategoriesCompanyLabel() {
  final company = TenantContext.instance.activeCompany;
  if (company != null && company.companyName.isNotEmpty) {
    return company.companyName;
  }
  final ref = tenantProductCategoriesCompanyRef();
  if (ref != null) {
    return ref.id;
  }
  return null;
}

bool ensureSingleCompanyForCatalogWrite(BuildContext context) {
  if (!ensureActiveCompanyForWrite(context)) {
    return false;
  }
  if (TenantContext.instance.isViewingAllCompanies) {
    final label = tenantProductCategoriesCompanyLabel();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          label != null
              ? 'Managing categories for $label only.'
              : 'Managing categories for the selected company only.',
        ),
      ),
    );
  }
  return true;
}

class _ManageProductCategoriesPanel extends StatefulWidget {
  const _ManageProductCategoriesPanel({
    required this.companyLabel,
    required this.onSavingChanged,
  });

  final String? companyLabel;
  final ValueChanged<bool> onSavingChanged;

  @override
  State<_ManageProductCategoriesPanel> createState() =>
      _ManageProductCategoriesPanelState();
}

class _ManageProductCategoriesPanelState
    extends State<_ManageProductCategoriesPanel> {
  final _addController = TextEditingController();
  List<String> _categories = const [];
  bool _loading = true;
  bool _synced = false;
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
    final docRef = tenantProductCategoriesDocRef();
    if (docRef == null) {
      return;
    }
    _subscription = docRef.snapshots().listen(
      (snapshot) {
        if (!mounted) {
          return;
        }
        setState(() {
          _categories = parseProductCategoriesFromData(
            snapshot.data() as Map<String, dynamic>?,
          );
          _synced = true;
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
          _synced = false;
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
      final categories = await loadManagedProductCategoriesWithFallback();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = categories;
        _synced = categories.isNotEmpty;
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
    final error = await addTenantProductCategory(_addController.text);
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
    final productCount = await countTenantProductsInCategory(category);
    if (!mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmContext) {
        return AlertDialog(
          title: const Text('Delete category?'),
          content: Text(
            productCount > 0
                ? '$productCount product(s) still use "$category". '
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
    final error = await removeTenantProductCategory(category);
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
            hintText: 'e.g. Hand Bouquet',
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

Future<void> showManageProductCategoriesDialog(BuildContext context) async {
  if (!ensureSingleCompanyForCatalogWrite(context)) {
    return;
  }

  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Manage Categories'),
            content: SizedBox(
              width: double.maxFinite,
              child: _ManageProductCategoriesPanel(
                companyLabel: tenantProductCategoriesCompanyLabel(),
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
