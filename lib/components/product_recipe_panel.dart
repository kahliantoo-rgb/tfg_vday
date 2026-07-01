import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/material_category_helpers.dart';
import '/backend/material_helpers.dart';
import '/backend/product_recipe_helpers.dart';
import '/backend/schema/material_record.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class ProductRecipePanel extends StatefulWidget {
  const ProductRecipePanel({
    super.key,
    required this.lines,
    required this.onChanged,
    this.productCategorySelected = true,
  });

  final List<ProductRecipeLine> lines;
  final ValueChanged<List<ProductRecipeLine>> onChanged;
  final bool productCategorySelected;

  @override
  State<ProductRecipePanel> createState() => _ProductRecipePanelState();
}

class _ProductRecipePanelState extends State<ProductRecipePanel> {
  String? _selectedMaterialCategory;
  MaterialRecord? _selectedMaterial;
  final _searchController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');

  @override
  void dispose() {
    _searchController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _syncMaterialSelection(List<MaterialRecord> filteredMaterials) {
    if (_selectedMaterial == null) {
      return;
    }
    final stillValid = filteredMaterials.any(
      (item) => item.reference.path == _selectedMaterial!.reference.path,
    );
    if (!stillValid) {
      _selectedMaterial = null;
    }
  }

  void _addLine() {
    final material = _selectedMaterial;
    if (material == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a material from the list first.')),
      );
      return;
    }
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0.')),
      );
      return;
    }
    final updated = [
      ...widget.lines,
      productRecipeLineFromMaterial(material, qty: qty),
    ];
    widget.onChanged(updated);
    setState(() {
      _qtyController.text = '1';
      _selectedMaterial = null;
    });
  }

  void _removeLine(int index) {
    final updated = [...widget.lines]..removeAt(index);
    widget.onChanged(updated);
  }

  Future<void> _editLine(int index) async {
    final line = widget.lines[index];
    final nameController = TextEditingController(text: line.materialName);
    final qtyController = TextEditingController(
      text: line.qty == line.qty.roundToDouble()
          ? line.qty.toInt().toString()
          : line.qty.toStringAsFixed(2),
    );

    final updatedLine = await showDialog<ProductRecipeLine>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit material'),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Material name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final qty = double.tryParse(qtyController.text.trim()) ?? 0;
                if (name.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Material name is required.'),
                    ),
                  );
                  return;
                }
                if (qty <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Quantity must be greater than 0.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  line.copyWith(materialName: name, qty: qty),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    qtyController.dispose();

    if (updatedLine == null || !mounted) {
      return;
    }

    final updated = [...widget.lines];
    updated[index] = updatedLine;
    widget.onChanged(updated);
  }

  String _formatRecipeQty(ProductRecipeLine line) {
    final qtyLabel = line.qty == line.qty.roundToDouble()
        ? line.qty.toInt().toString()
        : line.qty.toStringAsFixed(2);
    final unit = line.unit.trim();
    if (unit.isEmpty) {
      return qtyLabel;
    }
    return '$qtyLabel $unit';
  }

  Widget _buildMaterialSearchAndFilter({
    required FlutterFlowTheme theme,
    required List<String> categories,
  }) {
    final hasSearchText = _searchController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search name, SKU, category',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: hasSearchText
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: theme.secondaryBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.alternate),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.alternate),
            ),
          ),
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Category',
              style: theme.labelMedium.override(
                color: theme.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedMaterialCategory == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedMaterialCategory = null;
                      _selectedMaterial = null;
                    });
                  },
                ),
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedMaterialCategory == category,
                      onSelected: (_) {
                        setState(() {
                          _selectedMaterialCategory = category;
                          _selectedMaterial = null;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMaterialListTile(
    MaterialRecord material,
    FlutterFlowTheme theme,
  ) {
    final selected =
        _selectedMaterial?.reference.path == material.reference.path;
    final subtitleParts = <String>[
      if (material.unit.trim().isNotEmpty) material.unit.trim(),
      if (material.sku.trim().isNotEmpty) 'SKU: ${material.sku.trim()}',
      if (material.category.trim().isNotEmpty) material.category.trim(),
    ];

    return Material(
      color: selected
          ? theme.primary.withValues(alpha: 0.08)
          : theme.secondaryBackground,
      child: InkWell(
        onTap: () => setState(() => _selectedMaterial = material),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.alternate),
              left: BorderSide(
                color: selected ? theme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.labelLarge.override(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitleParts.isNotEmpty)
                      Text(
                        subtitleParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.labelSmall.override(
                          color: theme.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: theme.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recipe / Materials',
            style: theme.titleMedium.override(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            widget.productCategorySelected
                ? 'Search and filter materials, tap one to add.'
                : 'Select a product category above before adding materials.',
            style: theme.bodySmall.override(color: theme.secondaryText),
          ),
          const SizedBox(height: 12),
          if (!widget.productCategorySelected)
            Text(
              'Product category is required before you can add recipe materials.',
              style: theme.bodySmall.override(color: theme.secondaryText),
            )
          else
            StreamBuilder<List<MaterialRecord>>(
              stream: queryTenantMaterialRecord().map((materials) {
                final active = materials.where((m) => m.isActive).toList()
                  ..sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );
                return active;
              }),
              builder: (context, materialSnapshot) {
                return StreamBuilder<List<String>>(
                  stream: streamTenantMaterialCategories(),
                  builder: (context, categorySnapshot) {
                    final materials =
                        materialSnapshot.data ?? const <MaterialRecord>[];
                    if (materials.isEmpty) {
                      return Text(
                        'No materials yet. Add materials from Dashboard → Material List.',
                        style: theme.bodySmall.override(
                          color: theme.secondaryText,
                        ),
                      );
                    }

                    final categoryOptions = materialCategoryOptionsForMaterials(
                      categorySnapshot.data ?? defaultMaterialCategories,
                      materials,
                    );
                    final filteredMaterials = applyMaterialSelectionFilters(
                      materials: materials,
                      searchQuery: _searchController.text,
                      category: _selectedMaterialCategory,
                    );
                    _syncMaterialSelection(filteredMaterials);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMaterialSearchAndFilter(
                          theme: theme,
                          categories: categoryOptions,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.alternate),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: filteredMaterials.isEmpty
                              ? Center(
                                  child: Text(
                                    'No materials match your search or filter.',
                                    style: theme.bodySmall.override(
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: filteredMaterials.length,
                                  itemBuilder: (context, index) {
                                    return _buildMaterialListTile(
                                      filteredMaterials[index],
                                      theme,
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: 'Material name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: theme.secondaryBackground,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                child: Text(
                                  _selectedMaterial?.name ?? 'Select from list',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.bodyMedium.override(
                                    color: _selectedMaterial == null
                                        ? theme.secondaryText
                                        : theme.primaryText,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _qtyController,
                                enabled: _selectedMaterial != null,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: 'Qty',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: theme.secondaryBackground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: FilledButton(
                                onPressed: _selectedMaterial == null
                                    ? null
                                    : _addLine,
                                child: const Text('Add'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          if (widget.lines.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < widget.lines.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Material name',
                              style: theme.labelSmall.override(
                                color: theme.secondaryText,
                              ),
                            ),
                            Text(
                              widget.lines[i].materialName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodyMedium.override(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Qty',
                              style: theme.labelSmall.override(
                                color: theme.secondaryText,
                              ),
                            ),
                            Text(
                              _formatRecipeQty(widget.lines[i]),
                              style: theme.bodyMedium.override(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () => _editLine(i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () => _removeLine(i),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
