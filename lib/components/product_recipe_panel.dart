import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  final List<ProductRecipeLine> lines;
  final ValueChanged<List<ProductRecipeLine>> onChanged;

  @override
  State<ProductRecipePanel> createState() => _ProductRecipePanelState();
}

class _ProductRecipePanelState extends State<ProductRecipePanel> {
  MaterialRecord? _selectedMaterial;
  final _qtyController = TextEditingController(text: '1');

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _addLine(List<MaterialRecord> materials) {
    final material = _selectedMaterial;
    if (material == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a material first.')),
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
      _selectedMaterial = materials.firstWhere(
        (item) => item.reference.path == material.reference.path,
        orElse: () => material,
      );
    });
  }

  void _removeLine(int index) {
    final updated = [...widget.lines]..removeAt(index);
    widget.onChanged(updated);
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
            'List materials used to produce this product.',
            style: theme.bodySmall.override(color: theme.secondaryText),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<MaterialRecord>>(
            stream: queryTenantMaterialRecord().map((materials) {
              final active = materials.where((m) => m.isActive).toList()
                ..sort(
                  (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
              return active;
            }),
            builder: (context, snapshot) {
              final materials = snapshot.data ?? const <MaterialRecord>[];
              if (materials.isEmpty) {
                return Text(
                  'No materials yet. Add materials from Dashboard → Material List.',
                  style: theme.bodySmall.override(color: theme.secondaryText),
                );
              }

              _selectedMaterial ??= materials.first;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<MaterialRecord>(
                    value: materials.any(
                      (item) => item.reference.path == _selectedMaterial?.reference.path,
                    )
                        ? _selectedMaterial
                        : materials.first,
                    decoration: InputDecoration(
                      labelText: 'Material',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: theme.secondaryBackground,
                    ),
                    items: [
                      for (final material in materials)
                        DropdownMenuItem(
                          value: material,
                          child: Text(materialDisplayLabel(material)),
                        ),
                    ],
                    onChanged: (value) => setState(() => _selectedMaterial = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
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
                            filled: true,
                            fillColor: theme.secondaryBackground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _addLine(materials),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          if (widget.lines.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < widget.lines.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(formatProductRecipeLine(widget.lines[i])),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeLine(i),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
