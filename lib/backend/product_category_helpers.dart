import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

const defaultProductCategories = [
  'Hand Bouquet',
  'Wreath',
  'Opening Stand',
  'Table arrangement',
  'AdHoc',
];

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
    return List<String>.from(defaultProductCategories);
  }
  final raw = data['categories'];
  if (raw is! List) {
    return List<String>.from(defaultProductCategories);
  }
  final parsed = normalizeProductCategoryList(
    raw.whereType<String>(),
  );
  if (parsed.isEmpty) {
    return List<String>.from(defaultProductCategories);
  }
  return parsed;
}

DocumentReference? tenantProductCategoriesDocRef() {
  final companyRef = TenantContext.instance.writeCompanyRef ??
      TenantContext.instance.activeCompanyRef;
  if (companyRef == null) {
    return null;
  }
  return FirebaseFirestore.instance
      .collection('product_categories')
      .doc(companyRef.id);
}

Stream<List<String>> streamTenantProductCategories() {
  final docRef = tenantProductCategoriesDocRef();
  if (docRef == null) {
    return Stream.value(List<String>.from(defaultProductCategories));
  }
  return docRef.snapshots().map(
        (snapshot) => parseProductCategoriesFromData(
          snapshot.data() as Map<String, dynamic>?,
        ),
      );
}

Future<List<String>> loadTenantProductCategoriesOnce() async {
  final docRef = tenantProductCategoriesDocRef();
  if (docRef == null) {
    return List<String>.from(defaultProductCategories);
  }
  final snapshot = await docRef.get();
  return parseProductCategoriesFromData(
    snapshot.data() as Map<String, dynamic>?,
  );
}

Future<void> saveTenantProductCategories(List<String> categories) async {
  final docRef = tenantProductCategoriesDocRef();
  final companyRef = TenantContext.instance.writeCompanyRef ??
      TenantContext.instance.activeCompanyRef;
  if (docRef == null || companyRef == null) {
    return;
  }
  await docRef.set(
    {
      'companyRef': companyRef,
      'categories': normalizeProductCategoryList(categories),
      'updated_time': getCurrentTimestamp,
    },
    SetOptions(merge: true),
  );
}

Future<bool> addTenantProductCategory(String name) async {
  final trimmed = normalizeProductCategoryName(name);
  if (trimmed.isEmpty) {
    return false;
  }
  final current = await loadTenantProductCategoriesOnce();
  final exists = current.any(
    (category) => category.toLowerCase() == trimmed.toLowerCase(),
  );
  if (exists) {
    return false;
  }
  await saveTenantProductCategories([...current, trimmed]);
  return true;
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

Future<bool> removeTenantProductCategory(String category) async {
  final current = await loadTenantProductCategoriesOnce();
  final updated = current
      .where(
        (value) => value.toLowerCase() != category.toLowerCase(),
      )
      .toList();
  if (updated.length == current.length) {
    return false;
  }
  await saveTenantProductCategories(updated);
  return true;
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

Future<void> showManageProductCategoriesDialog(BuildContext context) async {
  if (!ensureActiveCompanyForWrite(context)) {
    return;
  }

  final addController = TextEditingController();
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
              child: StreamBuilder<List<String>>(
                stream: streamTenantProductCategories(),
                builder: (context, snapshot) {
                  final categories = snapshot.data ??
                      List<String>.from(defaultProductCategories);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: addController,
                        enabled: !saving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'New category',
                          hintText: 'e.g. Hand Bouquet',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) async {},
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  setDialogState(() => saving = true);
                                  final added = await addTenantProductCategory(
                                    addController.text,
                                  );
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (added) {
                                    addController.clear();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Category is empty or already exists.',
                                        ),
                                      ),
                                    );
                                  }
                                  setDialogState(() => saving = false);
                                },
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!snapshot.hasData)
                        const Center(child: CircularProgressIndicator())
                      else if (categories.isEmpty)
                        const Text('No categories yet.')
                      else
                        SizedBox(
                          height: 280,
                          child: ListView.separated(
                            itemCount: categories.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(category),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: saving
                                      ? null
                                      : () async {
                                          final productCount =
                                              await countTenantProductsInCategory(
                                            category,
                                          );
                                          if (!context.mounted) {
                                            return;
                                          }
                                          final confirmed =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (confirmContext) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'Delete category?',
                                                ),
                                                content: Text(
                                                  productCount > 0
                                                      ? '$productCount product(s) still use "$category". '
                                                          'They will keep this category, but it will be removed from the picker.'
                                                      : 'Remove "$category" from the category list?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          confirmContext,
                                                        ).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          confirmContext,
                                                        ).pop(true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          if (confirmed != true) {
                                            return;
                                          }
                                          setDialogState(() => saving = true);
                                          await removeTenantProductCategory(
                                            category,
                                          );
                                          if (context.mounted) {
                                            setDialogState(
                                              () => saving = false,
                                            );
                                          }
                                        },
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    },
  );

  addController.dispose();
}
