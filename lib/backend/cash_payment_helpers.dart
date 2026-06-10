import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/backend.dart';
import '/backend/order_balance_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/flutter_flow/custom_functions.dart' as functions;

class PaymentAmountResult {
  const PaymentAmountResult({
    required this.receivedThisTime,
  });

  final double receivedThisTime;
}

@Deprecated('Use PaymentAmountResult')
typedef CashPaymentResult = PaymentAmountResult;

String formatCashMoney(double value) => '\$${value.toStringAsFixed(2)}';

Future<double> loadOrderSaleTotal(DocumentReference orderRef) async {
  final items = activeOrderItems(
    await queryOrderItemRecordOnce(
      queryBuilder: (query) => query.where('orderRef', isEqualTo: orderRef),
    ),
  );
  if (items.isEmpty) {
    final order = await OrdersRecord.getDocumentOnce(orderRef);
    return resolveOrderSaleTotal(order, 0);
  }
  return functions.calculationTotal(
    items.map((item) => item.price).toList(),
    items.map((item) => item.qty).toList(),
  );
}

Future<PaymentApplicationResult> applyPaymentAmountToOrder({
  required DocumentReference orderRef,
  required String paymentType,
  required double saleTotal,
  required double receivedThisTime,
}) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  final previousPaid = readOrderAmountPaid(order);
  final applied = applyPaymentAmount(
    saleTotal: saleTotal,
    previousPaid: previousPaid,
    receivedThisTime: receivedThisTime,
  );
  final isCash = paymentType == 'Cash';
  await writeOrderPaymentBalance(
    orderRef,
    applied: applied,
    paymentType: paymentType,
    cashReceivedThisTime: isCash ? receivedThisTime : null,
    cashChange: isCash ? applied.change : 0,
  );
  return applied;
}

@Deprecated('Use applyPaymentAmountToOrder')
Future<PaymentApplicationResult> applyCashPaymentToOrder({
  required DocumentReference orderRef,
  required double saleTotal,
  required double receivedThisTime,
}) =>
    applyPaymentAmountToOrder(
      orderRef: orderRef,
      paymentType: 'Cash',
      saleTotal: saleTotal,
      receivedThisTime: receivedThisTime,
    );

Future<PaymentAmountResult?> showPaymentAmountDialog(
  BuildContext context, {
  required String paymentType,
  required String paymentLabel,
  required double saleTotal,
  double amountAlreadyPaid = 0,
}) async {
  if (saleTotal <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order total must be greater than zero.')),
    );
    return null;
  }

  final balanceDue = calculateBalanceDue(
    saleTotal: saleTotal,
    amountPaid: amountAlreadyPaid,
  );
  if (balanceDue <= 0.005) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This order is already fully paid.')),
    );
    return null;
  }

  final isCash = paymentType == 'Cash';
  final controller = TextEditingController();
  String? errorText;

  final result = await showDialog<PaymentAmountResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final parsed = double.tryParse(controller.text.trim());
        final received = parsed ?? 0;
        final projected = applyPaymentAmount(
          saleTotal: saleTotal,
          previousPaid: amountAlreadyPaid,
          receivedThisTime: received,
        );

        void submitExact() {
          Navigator.pop(
            dialogContext,
            PaymentAmountResult(receivedThisTime: balanceDue),
          );
        }

        void submitReceived() {
          if (parsed == null || parsed <= 0) {
            setDialogState(() {
              errorText = 'Enter amount received';
            });
            return;
          }
          Navigator.pop(
            dialogContext,
            PaymentAmountResult(receivedThisTime: parsed),
          );
        }

        return AlertDialog(
          title: Text('$paymentLabel payment'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sale total: ${formatCashMoney(saleTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (amountAlreadyPaid > 0.005) ...[
                  const SizedBox(height: 6),
                  Text('Already paid: ${formatCashMoney(amountAlreadyPaid)}'),
                  Text(
                    'Balance due: ${formatCashMoney(balanceDue)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount received now',
                    hintText: 'e.g. ${balanceDue.toStringAsFixed(2)}',
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                    setDialogState(() {});
                  },
                  onSubmitted: (_) => submitReceived(),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: submitExact,
                  child: Text('Exact ${formatCashMoney(balanceDue)}'),
                ),
                if (parsed != null && parsed > 0) ...[
                  if (isCash && projected.change > 0.005)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Change: ${formatCashMoney(projected.change)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else if (projected.balanceDue > 0.005)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Remaining balance: '
                        '${formatCashMoney(projected.balanceDue)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    )
                  else if (!isCash && projected.change > 0.005)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Amount applied: ${formatCashMoney(balanceDue)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: submitReceived,
              child: const Text('Confirm payment'),
            ),
          ],
        );
      },
    ),
  );

  controller.dispose();
  return result;
}

Future<PaymentAmountResult?> showCashReceivedDialog(
  BuildContext context, {
  required double saleTotal,
  double amountAlreadyPaid = 0,
}) =>
    showPaymentAmountDialog(
      context,
      paymentType: 'Cash',
      paymentLabel: 'Cash',
      saleTotal: saleTotal,
      amountAlreadyPaid: amountAlreadyPaid,
    );

Future<PaymentApplicationResult?> handlePaymentMethodSelection(
  BuildContext context, {
  required DocumentReference orderRef,
  required String paymentType,
  required String paymentLabel,
  double? saleTotal,
  Future<void> Function(PaymentApplicationResult applied)? onFullyPaid,
}) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  final total = saleTotal ?? await loadOrderSaleTotal(orderRef);
  if (!context.mounted) {
    return null;
  }

  final result = await showPaymentAmountDialog(
    context,
    paymentType: paymentType,
    paymentLabel: paymentLabel,
    saleTotal: total,
    amountAlreadyPaid: readOrderAmountPaid(order),
  );
  if (result == null || !context.mounted) {
    return null;
  }

  final applied = await applyPaymentAmountToOrder(
    orderRef: orderRef,
    paymentType: paymentType,
    saleTotal: total,
    receivedThisTime: result.receivedThisTime,
  );
  if (!context.mounted) {
    return applied;
  }

  if (paymentType == 'Cash' && applied.change > 0.005) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Change: ${formatCashMoney(applied.change)}')),
    );
  } else if (applied.balanceDue > 0.005) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Partial payment recorded. Balance: '
          '${formatCashMoney(applied.balanceDue)}',
        ),
      ),
    );
  }

  if (applied.isFullyPaid && onFullyPaid != null) {
    await onFullyPaid(applied);
  }

  return applied;
}

Future<PaymentApplicationResult?> handleExactPaymentMethodSelection(
  BuildContext context, {
  required DocumentReference orderRef,
  required String paymentType,
  required String paymentLabel,
  double? saleTotal,
  Future<void> Function(PaymentApplicationResult applied)? onFullyPaid,
}) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  final total = saleTotal ?? await loadOrderSaleTotal(orderRef);
  if (total <= 0) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order total must be greater than zero.')),
      );
    }
    return null;
  }

  final balanceDue = calculateBalanceDue(
    saleTotal: total,
    amountPaid: readOrderAmountPaid(order),
  );
  if (balanceDue <= 0.005) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This order is already fully paid.')),
      );
    }
    return null;
  }

  final applied = await applyPaymentAmountToOrder(
    orderRef: orderRef,
    paymentType: paymentType,
    saleTotal: total,
    receivedThisTime: balanceDue,
  );
  if (!context.mounted) {
    return applied;
  }

  if (applied.isFullyPaid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$paymentLabel payment recorded.')),
    );
  } else if (applied.balanceDue > 0.005) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Partial payment recorded. Balance: '
          '${formatCashMoney(applied.balanceDue)}',
        ),
      ),
    );
  }

  if (applied.isFullyPaid && onFullyPaid != null) {
    await onFullyPaid(applied);
  }

  return applied;
}

Future<PaymentApplicationResult?> handleCashPaymentSelection(
  BuildContext context, {
  required DocumentReference orderRef,
  double? saleTotal,
  Future<void> Function(PaymentApplicationResult applied)? onFullyPaid,
}) =>
    handlePaymentMethodSelection(
      context,
      orderRef: orderRef,
      paymentType: 'Cash',
      paymentLabel: 'Cash',
      saleTotal: saleTotal,
      onFullyPaid: onFullyPaid,
    );

Future<bool> handleFullyPaidButton(
  BuildContext context, {
  required DocumentReference orderRef,
  required double saleTotal,
  Future<void> Function()? onFullyPaid,
}) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  final balance = order.balanceDue > 0
      ? order.balanceDue
      : calculateBalanceDue(
          saleTotal: saleTotal,
          amountPaid: readOrderAmountPaid(order),
        );
  if (balance <= 0.005) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This order is already fully paid.')),
    );
    return false;
  }

  if (!context.mounted) {
    return false;
  }

  final paymentType = await ensurePaymentTypeSelected(
    context,
    currentPaymentType: order.paymentType,
  );
  if (paymentType == null || !context.mounted) {
    return false;
  }

  await markOrderFullyPaid(
    orderRef,
    saleTotal: saleTotal,
    paymentType: paymentType,
  );

  if (!context.mounted) {
    return false;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Order marked as fully paid.')),
  );

  if (onFullyPaid != null) {
    await onFullyPaid();
  }
  return true;
}
