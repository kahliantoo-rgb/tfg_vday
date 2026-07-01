import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/order_balance_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/backend/schema/enums/enums.dart';

/// Entry for status changes when [balance_due] remains on the order.
Future<void> showBalanceDueReminderDialog(
  BuildContext context, {
  required OrdersRecord order,
  required OrderStatus targetStatus,
  required double saleTotal,
}) async {
  final balance = order.balanceDue > 0
      ? order.balanceDue
      : calculateBalanceDue(
          saleTotal: saleTotal,
          amountPaid: readOrderAmountPaid(order),
        );
  if (balance <= 0.005) {
    return;
  }

  await showOutstandingBalanceDialog(
    context,
    orderRef: order.reference,
    order: order,
    targetStatus: targetStatus,
    saleTotal: saleTotal,
    balanceDue: balance,
  );
}

/// Shown when marking Ready to ship / Completed while [balance_due] remains.
Future<void> showOutstandingBalanceDialog(
  BuildContext context, {
  required DocumentReference orderRef,
  required OrdersRecord order,
  required OrderStatus targetStatus,
  required double saleTotal,
  required double balanceDue,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => OutstandingBalanceDialog(
      orderRef: orderRef,
      initialOrder: order,
      targetStatus: targetStatus,
      saleTotal: saleTotal,
      initialBalanceDue: balanceDue,
    ),
  );
}

class OutstandingBalanceDialog extends StatefulWidget {
  const OutstandingBalanceDialog({
    super.key,
    required this.orderRef,
    required this.initialOrder,
    required this.targetStatus,
    required this.saleTotal,
    required this.initialBalanceDue,
  });

  final DocumentReference orderRef;
  final OrdersRecord initialOrder;
  final OrderStatus targetStatus;
  final double saleTotal;
  final double initialBalanceDue;

  @override
  State<OutstandingBalanceDialog> createState() =>
      _OutstandingBalanceDialogState();
}

class _OutstandingBalanceDialogState extends State<OutstandingBalanceDialog> {
  late OrdersRecord _order;
  late String _paymentType;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _paymentType = widget.initialOrder.paymentType.trim().isNotEmpty
        ? widget.initialOrder.paymentType.trim()
        : 'Cash';
  }

  String get _statusLabel => widget.targetStatus == OrderStatus.completed
      ? 'Completed'
      : 'Ready to ship';

  double get _amountPaid => readOrderAmountPaid(_order);

  double get _balanceDue {
    if (_order.balanceDue > 0.005) {
      return _order.balanceDue;
    }
    return calculateBalanceDue(
      saleTotal: widget.saleTotal,
      amountPaid: _amountPaid,
    );
  }

  Future<void> _reloadOrder() async {
    final refreshed = await OrdersRecord.getDocumentOnce(widget.orderRef);
    if (!mounted) {
      return;
    }
    setState(() {
      _order = refreshed;
      if (refreshed.paymentType.trim().isNotEmpty) {
        _paymentType = refreshed.paymentType.trim();
      }
    });
  }

  Future<void> _changePaymentMode() async {
    final selected = await showPaymentModePickerDialog(context);
    if (selected == null || !mounted) {
      return;
    }
    setState(() => _paymentType = selected);
    await widget.orderRef.update(
      createOrdersRecordData(paymentType: selected),
    );
    await _reloadOrder();
  }

  Future<void> _payBalance() async {
    if (_paying) {
      return;
    }
    setState(() => _paying = true);
    try {
      var paymentType = _paymentType.trim();
      if (paymentType.isEmpty) {
        final picked = await showPaymentModePickerDialog(context);
        if (picked == null || !mounted) {
          return;
        }
        paymentType = picked;
        setState(() => _paymentType = picked);
        await widget.orderRef.update(
          createOrdersRecordData(paymentType: picked),
        );
      }

      if (isCreditPaymentType(paymentType)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Credit term saved. Collect payment when due.',
              ),
            ),
          );
        }
        return;
      }

      PaymentApplicationResult? applied;
      if (requiresPaymentAmountEntry(paymentType)) {
        if (!mounted) {
          return;
        }
        applied = await handlePaymentMethodSelection(
          context,
          orderRef: widget.orderRef,
          paymentType: paymentType,
          paymentLabel: paymentMethodLabel(paymentType),
          saleTotal: widget.saleTotal,
        );
      } else if (usesExactPaymentAmount(paymentType)) {
        if (!mounted) {
          return;
        }
        applied = await handleExactPaymentMethodSelection(
          context,
          orderRef: widget.orderRef,
          paymentType: paymentType,
          paymentLabel: paymentMethodLabel(paymentType),
          saleTotal: widget.saleTotal,
        );
      }

      if (!mounted) {
        return;
      }

      await _reloadOrder();

      if (!mounted) {
        return;
      }

      if (applied?.isFullyPaid == true || _balanceDue <= 0.005) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded. Balance cleared.')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(describeFirestoreError(error)),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Outstanding balance'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This order is being marked as $_statusLabel but payment '
              'is not complete.',
            ),
            const SizedBox(height: 16),
            _amountRow('Order total', widget.saleTotal),
            const SizedBox(height: 8),
            _amountRow('Amount paid', _amountPaid),
            const SizedBox(height: 8),
            _amountRow(
              'Balance due',
              _balanceDue,
              emphasized: true,
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Payment mode'),
              subtitle: Text(formatPaymentMethodLabel(_paymentType)),
              trailing: TextButton(
                onPressed: _paying ? null : _changePaymentMode,
                child: const Text('Change'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _paying ? null : () => Navigator.pop(context),
          child: const Text('Continue'),
        ),
        FilledButton(
          onPressed: _paying || _balanceDue <= 0.005 ? null : _payBalance,
          child: _paying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Pay ${formatCashMoney(_balanceDue)}'),
        ),
      ],
    );
  }

  Widget _amountRow(String label, double amount, {bool emphasized = false}) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.error,
            )
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(formatCashMoney(amount), style: style),
      ],
    );
  }
}
