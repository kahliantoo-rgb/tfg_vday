import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/backend.dart';
import '/backend/create_order_service.dart';
import '/backend/material_cost_snapshot_helpers.dart';
import '/backend/order_balance_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/flutter_flow/custom_functions.dart' as functions;

class PaymentAmountResult {
  const PaymentAmountResult({
    required this.receivedThisTime,
  });

  final double receivedThisTime;
}

/// Staged payment on order summary — applied when staff taps Payment Done.
class PendingOrderPaymentSelection {
  const PendingOrderPaymentSelection({
    required this.paymentType,
    required this.amountReceivedThisTime,
  });

  final String paymentType;
  final double amountReceivedThisTime;
}

String describePendingOrderPayment(PendingOrderPaymentSelection selection) {
  if (isCreditPaymentType(selection.paymentType)) {
    return '${formatPaymentMethodLabel(selection.paymentType)} selected — tap Payment Done to confirm';
  }
  return '${paymentMethodLabel(selection.paymentType)} '
      '${formatCashMoney(selection.amountReceivedThisTime)} selected — '
      'tap Payment Done to confirm';
}

void _showPaymentWriteError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(describeFirestoreError(error)),
      duration: const Duration(seconds: 8),
    ),
  );
}

@Deprecated('Use PaymentAmountResult')
typedef CashPaymentResult = PaymentAmountResult;

String formatCashMoney(double value) => '\$${value.toStringAsFixed(2)}';

Future<double> loadOrderSaleTotal(DocumentReference orderRef) async {
  final items = activeOrderItems(await queryOrderItemsForOrderOnce(orderRef));
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
    order: order,
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
  String confirmButtonLabel = 'Confirm payment',
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
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.pop(
            dialogContext,
            PaymentAmountResult(receivedThisTime: balanceDue),
          );
        }

        void submitReceived() {
          final receivedThisTime = (parsed != null && parsed > 0)
              ? parsed
              : (!isCash ? balanceDue : null);
          if (receivedThisTime == null || receivedThisTime <= 0) {
            setDialogState(() {
              errorText = 'Enter amount received';
            });
            return;
          }
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.pop(
            dialogContext,
            PaymentAmountResult(receivedThisTime: receivedThisTime),
          );
        }

        return AlertDialog(
          scrollable: true,
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
              child: Text(confirmButtonLabel),
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

  PaymentApplicationResult applied;
  try {
    applied = await applyPaymentAmountToOrder(
      orderRef: orderRef,
      paymentType: paymentType,
      saleTotal: total,
      receivedThisTime: result.receivedThisTime,
    );
  } catch (error) {
    if (context.mounted) {
      _showPaymentWriteError(context, error);
    }
    return null;
  }
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

  PaymentApplicationResult applied;
  try {
    applied = await applyPaymentAmountToOrder(
      orderRef: orderRef,
      paymentType: paymentType,
      saleTotal: total,
      receivedThisTime: balanceDue,
    );
  } catch (error) {
    if (context.mounted) {
      _showPaymentWriteError(context, error);
    }
    return null;
  }
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

Future<PendingOrderPaymentSelection?> selectPartialPaymentForSummary(
  BuildContext context, {
  required DocumentReference orderRef,
  required String paymentType,
  required String paymentLabel,
  double? saleTotal,
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
    confirmButtonLabel: 'Select amount',
  );
  if (result == null || !context.mounted) {
    return null;
  }

  final selection = PendingOrderPaymentSelection(
    paymentType: paymentType,
    amountReceivedThisTime: result.receivedThisTime,
  );
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(describePendingOrderPayment(selection))),
  );
  return selection;
}

Future<PendingOrderPaymentSelection?> selectExactPaymentForSummary(
  BuildContext context, {
  required DocumentReference orderRef,
  required String paymentType,
  required String paymentLabel,
  double? saleTotal,
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

  final selection = PendingOrderPaymentSelection(
    paymentType: paymentType,
    amountReceivedThisTime: balanceDue,
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(describePendingOrderPayment(selection))),
    );
  }
  return selection;
}

Future<PaymentApplicationResult?> applyPendingOrderPaymentSelection({
  required DocumentReference orderRef,
  required PendingOrderPaymentSelection selection,
  required double saleTotal,
}) async {
  if (isCreditPaymentType(selection.paymentType)) {
    await orderRef.update(
      createOrdersRecordData(paymentType: selection.paymentType),
    );
    await ensureOrderMaterialCostSnapshot(orderRef);
    return null;
  }

  return applyPaymentAmountToOrder(
    orderRef: orderRef,
    paymentType: selection.paymentType,
    saleTotal: saleTotal,
    receivedThisTime: selection.amountReceivedThisTime,
  );
}

Future<bool> completeOrderSummaryPayment(
  BuildContext context, {
  required DocumentReference orderRef,
  required double saleTotal,
  required PendingOrderPaymentSelection? pendingSelection,
}) async {
  if (pendingSelection == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select a payment method and amount first, then tap Payment Done.',
          ),
        ),
      );
    }
    return false;
  }

  PaymentApplicationResult? applied;
  try {
    applied = await applyPendingOrderPaymentSelection(
      orderRef: orderRef,
      selection: pendingSelection,
      saleTotal: saleTotal,
    );
  } catch (error) {
    if (context.mounted) {
      _showPaymentWriteError(context, error);
    }
    return false;
  }
  if (!context.mounted) {
    return true;
  }

  if (isCreditPaymentType(pendingSelection.paymentType)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${formatPaymentMethodLabel(pendingSelection.paymentType)} saved.',
        ),
      ),
    );
    return true;
  }

  if (applied == null) {
    return false;
  }

  if (pendingSelection.paymentType == 'Cash' && applied.change > 0.005) {
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
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${paymentMethodLabel(pendingSelection.paymentType)} payment recorded.',
        ),
      ),
    );
  }

  return true;
}

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
