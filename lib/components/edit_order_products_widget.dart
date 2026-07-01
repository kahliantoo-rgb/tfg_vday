import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/record_edit_permissions.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/backend.dart';
import '/backend/order_item_helpers.dart';
import '/components/order_item_qty_stepper.dart';
import '/components/order_product_add_panel.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class _LineEditor {
  _LineEditor({
    required this.item,
    required this.qtyController,
    required this.priceController,
  });

  final OrderItemRecord item;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  void dispose() {
    EasyDebounce.cancel('edit-order-item-${item.reference.id}');
    qtyController.dispose();
    priceController.dispose();
  }
}

class EditOrderProductsWidget extends StatefulWidget {
  const EditOrderProductsWidget({
    super.key,
    required this.orderRef,
    required this.order,
  });

  final DocumentReference orderRef;
  final OrdersRecord order;

  @override
  State<EditOrderProductsWidget> createState() =>
      _EditOrderProductsWidgetState();
}

class _EditOrderProductsWidgetState extends State<EditOrderProductsWidget> {
  List<_LineEditor>? _lines;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    for (final line in _lines ?? const <_LineEditor>[]) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final items = await queryOrderItemsForOrderOnce(widget.orderRef);
      for (final old in _lines ?? const <_LineEditor>[]) {
        old.dispose();
      }
      _lines = items
          .map(
            (item) {
              final line = _LineEditor(
                item: item,
                qtyController:
                    TextEditingController(text: item.qty.toString()),
                priceController: TextEditingController(
                  text: item.price.toString(),
                ),
              );
              line.qtyController.addListener(() => _scheduleLineSave(line));
              line.priceController.addListener(() => _scheduleLineSave(line));
              return line;
            },
          )
          .toList();
    } catch (e) {
      _loadError = e.toString();
      _lines = [];
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _scheduleLineSave(_LineEditor line) {
    EasyDebounce.debounce(
      'edit-order-item-${line.item.reference.id}',
      const Duration(milliseconds: 500),
      () => _saveLine(line, showSuccessMessage: false),
    );
  }

  Future<void> _saveLine(
    _LineEditor line, {
    bool showSuccessMessage = true,
  }) async {
    if (_saving) {
      return;
    }
    try {
      assertCanEditOrderRecord(currentViewerRole(), widget.order);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
      return;
    }

    final qty = int.tryParse(line.qtyController.text.trim()) ?? 0;
    final price = double.tryParse(line.priceController.text.trim()) ?? 0;
    if (qty <= 0) {
      return;
    }

    setState(() => _saving = true);
    try {
      await line.item.reference.update(
        createOrderItemRecordData(
          qty: qty,
          price: price,
          subtotal: price * qty,
        ),
      );
      await recalculateOrderTotals(widget.orderRef);
      if (showSuccessMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Products updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveAll() async {
    final lines = _lines;
    if (lines == null) {
      return;
    }
    try {
      assertCanEditOrderRecord(currentViewerRole(), widget.order);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      for (final line in lines) {
        final qty = int.tryParse(line.qtyController.text.trim()) ?? 0;
        final price = double.tryParse(line.priceController.text.trim()) ?? 0;
        if (qty <= 0) {
          throw Exception('Quantity must be at least 1');
        }
        await line.item.reference.update(
          createOrderItemRecordData(
            qty: qty,
            price: price,
            subtotal: price * qty,
          ),
        );
      }
      await recalculateOrderTotals(widget.orderRef);
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Products updated')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteLine(_LineEditor line) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove "${line.item.name}" from this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    await line.item.reference.delete();
    line.dispose();
    setState(() => _lines?.remove(line));
    await _saveTotalsAfterDelete();
  }

  Future<void> _saveTotalsAfterDelete() async {
    await recalculateOrderTotals(widget.orderRef);
  }

  void _addProducts() {
    showOrderProductAddPanel(
      context,
      orderRef: widget.orderRef,
      onItemsChanged: _loadItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit Products',
                      style: FlutterFlowTheme.of(context).headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (_loadError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_loadError!),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: _lines!.length,
                  itemBuilder: (context, index) {
                    final line = _lines![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    line.item.name,
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: _saving
                                      ? null
                                      : () => _deleteLine(line),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: OrderItemQtyFieldStepper(
                                    controller: line.qtyController,
                                    enabled: !_saving,
                                    onChanged: () => _scheduleLineSave(line),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: line.priceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Price',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  FFButtonWidget(
                    onPressed: _addProducts,
                    text: 'Add Products',
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 44,
                      color: FlutterFlowTheme.of(context).secondary,
                      textStyle: FlutterFlowTheme.of(context)
                          .titleSmall
                          .override(
                            font: GoogleFonts.interTight(),
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FFButtonWidget(
                    onPressed: _saving || _loading ? null : _saveAll,
                    text: _saving ? 'Saving...' : 'Done',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48,
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle: FlutterFlowTheme.of(context)
                          .titleSmall
                          .override(
                            font: GoogleFonts.interTight(),
                            color: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showEditOrderProductsSheet(
  BuildContext context, {
  required DocumentReference orderRef,
  required OrdersRecord order,
}) {
  showModalBottomSheet(
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    context: context,
    builder: (sheetContext) {
      return Padding(
        padding: MediaQuery.viewInsetsOf(sheetContext),
        child: EditOrderProductsWidget(
          orderRef: orderRef,
          order: order,
        ),
      );
    },
  );
}
