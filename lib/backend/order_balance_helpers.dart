import 'package:flutter/material.dart';

import '/backend/backend.dart';

class PaymentApplicationResult {
  const PaymentApplicationResult({
    required this.saleTotal,
    required this.previousPaid,
    required this.receivedThisTime,
    required this.amountPaid,
    required this.balanceDue,
    required this.change,
  });

  final double saleTotal;
  final double previousPaid;
  final double receivedThisTime;
  final double amountPaid;
  final double balanceDue;
  final double change;

  bool get isFullyPaid => balanceDue <= 0.005;
}

double resolveOrderSaleTotal(OrdersRecord order, double computedFromItems) {
  if (computedFromItems > 0) {
    return computedFromItems;
  }
  if (order.totalAmount > 0) {
    return order.totalAmount;
  }
  if (order.total > 0) {
    return order.total;
  }
  return 0;
}

double readOrderAmountPaid(OrdersRecord order) {
  if (order.amountPaid > 0) {
    return order.amountPaid;
  }
  return 0;
}

double calculateBalanceDue({
  required double saleTotal,
  required double amountPaid,
}) {
  if (saleTotal <= 0) {
    return 0;
  }
  final balance = saleTotal - amountPaid;
  return balance > 0.005 ? balance : 0;
}

PaymentApplicationResult applyPaymentAmount({
  required double saleTotal,
  required double previousPaid,
  required double receivedThisTime,
}) {
  final cappedPaid = previousPaid + receivedThisTime;
  final change = cappedPaid > saleTotal ? cappedPaid - saleTotal : 0.0;
  final amountPaid = cappedPaid > saleTotal ? saleTotal : cappedPaid;
  final balanceDue = calculateBalanceDue(
    saleTotal: saleTotal,
    amountPaid: amountPaid,
  );
  return PaymentApplicationResult(
    saleTotal: saleTotal,
    previousPaid: previousPaid,
    receivedThisTime: receivedThisTime,
    amountPaid: amountPaid,
    balanceDue: balanceDue,
    change: change,
  );
}

Future<void> writeOrderPaymentBalance(
  DocumentReference orderRef, {
  required PaymentApplicationResult applied,
  required String paymentType,
  double? cashReceivedThisTime,
  double? cashChange,
}) async {
  final isCash = paymentType == 'Cash';
  await orderRef.update(
    createOrdersRecordData(
      paymentType: paymentType,
      amountPaid: applied.amountPaid,
      balanceDue: applied.balanceDue,
      cashReceived: isCash ? cashReceivedThisTime : 0,
      cashChange: isCash ? (cashChange ?? applied.change) : 0,
      totalAmount: applied.saleTotal,
      total: applied.saleTotal,
    ),
  );
}

Future<void> markOrderFullyPaid(
  DocumentReference orderRef, {
  required double saleTotal,
  required String paymentType,
}) async {
  await orderRef.update(
    createOrdersRecordData(
      paymentType: paymentType,
      amountPaid: saleTotal,
      balanceDue: 0,
      cashChange: 0,
      totalAmount: saleTotal,
      total: saleTotal,
    ),
  );
}

Future<String?> ensurePaymentTypeSelected(
  BuildContext context, {
  required String currentPaymentType,
}) async {
  if (currentPaymentType.trim().isNotEmpty) {
    return currentPaymentType.trim();
  }
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Select payment method'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, 'Cash'),
          child: const Text('Cash'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, 'Paynow'),
          child: const Text('PayNow'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, 'Card'),
          child: const Text('Card'),
        ),
      ],
    ),
  );
}

