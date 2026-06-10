import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '/backend/schema/counter_record.dart';
import '/backend/tenant_context.dart';

/// Generates sequential order IDs via Firestore counters scoped by month
/// (`default_delivery_JUN26`, `default_retail_JUN26`, …).
class OrderIdService {
  static const deliveryCounterId = 'default_delivery';
  static const retailCounterId = 'default_retail';
  static const invoiceCounterId = 'default_invoice';

  static String _orderPeriodSuffix([DateTime? when]) {
    final date = when ?? DateTime.now();
    return DateFormat('MMMyy', 'en_US').format(date).toUpperCase();
  }

  /// Counter doc id for a channel + month, e.g. `default_delivery_JUN26`.
  static String counterDocId(String channel, {String? period}) {
    final base = switch (channel) {
      'delivery' => deliveryCounterId,
      'retail' => retailCounterId,
      'invoice' => invoiceCounterId,
      _ => 'default_$channel',
    };
    final suffix = period ?? _orderPeriodSuffix();
    return '${base}_$suffix';
  }

  static DocumentReference _counterRef(String counterId) =>
      CounterRecord.collection.doc(counterId);

  static bool isRetailOrderId(String? orderId) {
    if (orderId == null || orderId.isEmpty) {
      return false;
    }
    if (RegExp(r'^TFG-[A-Z]{3}\d{2}-WI000\d+$').hasMatch(orderId)) {
      return true;
    }
    return orderId.startsWith('TFG-WI');
  }

  static bool isDeliveryOrderId(String? orderId) {
    if (orderId == null || orderId.isEmpty) {
      return false;
    }
    if (RegExp(r'^TFG-[A-Z]{3}\d{2}-000\d+$').hasMatch(orderId)) {
      return true;
    }
    return RegExp(r'^TFG-\d{4}-\d+$').hasMatch(orderId);
  }

  static Future<String> nextDeliveryOrderId() async {
    final period = _orderPeriodSuffix();
    final seq = await _incrementCounter('delivery', period: period);
    return 'TFG-$period-000$seq';
  }

  static Future<String> nextRetailOrderId() async {
    final period = _orderPeriodSuffix();
    final seq = await _incrementCounter('retail', period: period);
    return 'TFG-$period-WI000$seq';
  }

  static Future<String> nextInvoiceNumber() async {
    final period = _orderPeriodSuffix();
    final seq = await _incrementCounter('invoice', period: period);
    return 'IN-TFG-$period-000$seq';
  }

  static bool isInvoiceNumber(String? invoiceNumber) {
    if (invoiceNumber == null || invoiceNumber.isEmpty) {
      return false;
    }
    return RegExp(r'^IN-TFG-[A-Z]{3}\d{2}-000\d+$').hasMatch(invoiceNumber);
  }

  static Future<int> _incrementCounter(
    String channel, {
    required String period,
  }) {
    final counterRef = _counterRef(counterDocId(channel, period: period));

    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(counterRef);
      final data = snap.data() as Map<String, dynamic>?;
      final current =
          snap.exists ? (data?['current'] as num?)?.toInt() ?? 0 : 0;
      final next = current + 1;

      final companyRef = TenantContext.instance.writeCompanyRef;
      final payload = <String, dynamic>{'current': next};
      if (companyRef != null) {
        payload['comR'] = companyRef;
      }
      tx.set(counterRef, payload, SetOptions(merge: true));
      return next;
    });
  }
}
