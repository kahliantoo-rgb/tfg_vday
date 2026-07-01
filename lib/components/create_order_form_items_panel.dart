import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/backend.dart';
import '/backend/order_item_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/components/order_item_qty_stepper.dart';
import '/components/order_product_add_panel.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Selected order line items on Create Order Form — editable qty/price above Submit.
class CreateOrderFormItemsPanel extends StatelessWidget {
  const CreateOrderFormItemsPanel({
    super.key,
    required this.orderRef,
  });

  final DocumentReference orderRef;

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return StreamBuilder<List<OrderItemRecord>>(
      stream: streamOrderLineItemsForOrder(orderRef),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final items = activeOrderItems(snapshot.data!);
        final total = functions.calculationTotal(
          items.map((item) => item.price).toList(),
          items.map((item) => item.qty).toList(),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected Products',
                    style: theme.titleMedium.override(
                      font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    showOrderProductAddPanel(
                      context,
                      orderRef: orderRef,
                      onItemsChanged: () async {},
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Add Products'),
                ),
              ],
            ),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.alternate),
                ),
                child: Text(
                  'No products selected yet. Tap Add Products to choose items.',
                  style: theme.bodySmall.override(
                    color: theme.secondaryText,
                  ),
                ),
              )
            else ...[
              for (final item in items)
                CreateOrderFormItemEditor(
                  key: ValueKey(item.reference.id),
                  item: item,
                  orderRef: orderRef,
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.alternate),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: theme.titleSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _money(total),
                      style: theme.titleSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.w700,
                        ),
                        color: theme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class CreateOrderFormItemEditor extends StatefulWidget {
  const CreateOrderFormItemEditor({
    super.key,
    required this.item,
    required this.orderRef,
  });

  final OrderItemRecord item;
  final DocumentReference orderRef;

  @override
  State<CreateOrderFormItemEditor> createState() =>
      _CreateOrderFormItemEditorState();
}

class _CreateOrderFormItemEditorState extends State<CreateOrderFormItemEditor> {
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _qtyController =
        TextEditingController(text: widget.item.qty.toString());
    _priceController =
        TextEditingController(text: widget.item.price.toString());
    _qtyController.addListener(_scheduleSave);
    _priceController.addListener(_scheduleSave);
  }

  @override
  void didUpdateWidget(covariant CreateOrderFormItemEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.reference.id != widget.item.reference.id) {
      _qtyController.text = widget.item.qty.toString();
      _priceController.text = widget.item.price.toString();
    }
  }

  @override
  void dispose() {
    EasyDebounce.cancel('create-form-item-${widget.item.reference.id}');
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    EasyDebounce.debounce(
      'create-form-item-${widget.item.reference.id}',
      const Duration(milliseconds: 500),
      () => _saveLine(),
    );
  }

  Future<void> _saveLine() async {
    if (_busy || !mounted) {
      return;
    }
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (qty <= 0) {
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.item.reference.update(
        createOrderItemRecordData(
          qty: qty,
          price: price,
          subtotal: price * qty,
        ),
      );
      await recalculateOrderTotals(widget.orderRef);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _removeLine() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove "${widget.item.name}" from this order?'),
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
    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await deleteOrderItemLine(
        item: widget.item,
        orderRef: widget.orderRef,
      );
      await recalculateOrderTotals(widget.orderRef);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final name =
        widget.item.name.isNotEmpty ? widget.item.name : 'Item';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: theme.titleSmall.override(
                    font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.error,
                  size: 20,
                ),
                onPressed: _busy ? null : _removeLine,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OrderItemQtyFieldStepper(
                  controller: _qtyController,
                  enabled: !_busy,
                  onChanged: _scheduleSave,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  enabled: !_busy,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Price',
                    isDense: true,
                    filled: true,
                    fillColor: theme.primaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
