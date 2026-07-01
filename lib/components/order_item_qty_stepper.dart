import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/order_item_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';

Future<void> _runQtyMutation(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not update quantity: $error')),
    );
  }
}

/// +/- controls and editable qty for checkout summary rows.
class OrderItemQtyStepper extends StatefulWidget {
  const OrderItemQtyStepper({
    super.key,
    required this.item,
    required this.orderRef,
  });

  final OrderItemRecord item;
  final DocumentReference orderRef;

  @override
  State<OrderItemQtyStepper> createState() => _OrderItemQtyStepperState();
}

class _OrderItemQtyStepperState extends State<OrderItemQtyStepper> {
  late final TextEditingController _qtyController;
  final FocusNode _qtyFocus = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.item.qty.toString());
    _qtyFocus.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(OrderItemQtyStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.qty != widget.item.qty && !_editing) {
      _qtyController.text = widget.item.qty.toString();
    }
  }

  @override
  void dispose() {
    _qtyFocus.removeListener(_handleFocusChange);
    _qtyFocus.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_qtyFocus.hasFocus && _editing) {
      _editing = false;
      _applyTypedQty();
    }
  }

  Future<void> _applyTypedQty() async {
    final parsed = int.tryParse(_qtyController.text.trim());
    if (parsed == null) {
      _qtyController.text = widget.item.qty.toString();
      return;
    }
    if (parsed == widget.item.qty) {
      return;
    }
    await _runQtyMutation(
      context,
      () => setOrderItemQuantity(
        item: widget.item,
        orderRef: widget.orderRef,
        qty: parsed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.item.qty >= 1)
          FlutterFlowIconButton(
            borderRadius: 16.0,
            buttonSize: 32.0,
            fillColor: theme.alternate,
            icon: Icon(
              Icons.remove,
              color: theme.primaryText,
              size: 16.0,
            ),
            onPressed: () => _runQtyMutation(
              context,
              () => decreaseOrderItemQuantityOrDelete(
                item: widget.item,
                orderRef: widget.orderRef,
              ),
            ),
          ),
        Container(
          width: 48.0,
          height: 32.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(
              color: theme.alternate,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _qtyController,
            focusNode: _qtyFocus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.bodyMedium.override(
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () => _editing = true,
            onSubmitted: (_) {
              _editing = false;
              _applyTypedQty();
            },
          ),
        ),
        FlutterFlowIconButton(
          borderRadius: 16.0,
          buttonSize: 32.0,
          fillColor: theme.primary,
          icon: Icon(
            Icons.add,
            color: theme.primaryBackground,
            size: 16.0,
          ),
          onPressed: () => _runQtyMutation(
            context,
            () => increaseOrderItemQuantity(
              item: widget.item,
              orderRef: widget.orderRef,
            ),
          ),
        ),
      ],
    );
  }
}

/// Qty field with +/- for order edit forms (controller-driven).
class OrderItemQtyFieldStepper extends StatelessWidget {
  const OrderItemQtyFieldStepper({
    super.key,
    required this.controller,
    required this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool enabled;

  void _bump(int delta) {
    final current = int.tryParse(controller.text.trim()) ?? 0;
    final next = current + delta;
    if (next <= 0) {
      return;
    }
    controller.text = next.toString();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: !enabled ? null : () => _bump(-1),
          icon: Icon(Icons.remove_circle_outline, color: theme.secondaryText),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Qty',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: !enabled ? null : () => _bump(1),
          icon: Icon(Icons.add_circle_outline, color: theme.primary),
        ),
      ],
    );
  }
}
