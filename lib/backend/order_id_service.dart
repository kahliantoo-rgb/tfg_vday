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
  static const customerCounterId = 'default_customer';
  static const int maxCustomerIdSequence = 1000;

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

  /// Next invoice number without incrementing the counter (confirm screen preview).
  static Future<String> previewNextInvoiceNumber() async {
    final period = _orderPeriodSuffix();
    final counterRef = _counterRef(counterDocId('invoice', period: period));
    try {
      final snap = await counterRef.get();
      final data = snap.data() as Map<String, dynamic>?;
      final current =
          snap.exists ? (data?['current'] as num?)?.toInt() ?? 0 : 0;
      return 'IN-TFG-$period-000${current + 1}';
    } catch (_) {
      return 'IN-TFG-$period-0001';
    }
  }

  static bool isInvoiceNumber(String? invoiceNumber) {
    if (invoiceNumber == null || invoiceNumber.isEmpty) {
      return false;
    }
    return RegExp(r'^IN-TFG-[A-Z]{3}\d{2}-000\d+$').hasMatch(invoiceNumber);
  }

  /// Public customer code: TFG01 … TFG99, TFG100 … TFG1000.
  static String formatCustomerId(int sequence) {
    if (sequence < 1 || sequence > maxCustomerIdSequence) {
      throw StateError(
        'Customer ID sequence must be between 1 and $maxCustomerIdSequence',
      );
    }
    if (sequence <= 99) {
      return 'TFG${sequence.toString().padLeft(2, '0')}';
    }
    return 'TFG$sequence';
  }

  static int? parseCustomerIdSequence(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final match = RegExp(r'^TFG(\d+)$').firstMatch(value.trim().toUpperCase());
    if (match == null) {
      return null;
    }
    final seq = int.tryParse(match.group(1)!);
    if (seq == null || seq < 1 || seq > maxCustomerIdSequence) {
      return null;
    }
    return seq;
  }

  static bool isCustomerPublicId(String? value) =>
      parseCustomerIdSequence(value) != null;

  /// Smallest reusable sequence, or next after [current] when pool is empty.
  static int? pickNextCustomerSequence({
    required int current,
    required List<int> available,
  }) {
    if (available.isNotEmpty) {
      return available.first;
    }
    if (current >= maxCustomerIdSequence) {
      return null;
    }
    return current + 1;
  }

  static List<int> addReleasedCustomerSequence(
    List<int> available,
    int sequence,
  ) {
    if (sequence < 1 || sequence > maxCustomerIdSequence) {
      return available;
    }
    final next = {...available, sequence}.toList()..sort();
    return next;
  }

  static Future<String> nextCustomerId() async {
    final counterRef = _counterRef(customerCounterId);

    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(counterRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final current = (data['current'] as num?)?.toInt() ?? 0;
      var available = List<int>.from(
        (data['available'] as List?)
                ?.map((value) => (value as num).toInt()) ??
            const [],
      )..sort();

      final seq = pickNextCustomerSequence(
        current: current,
        available: available,
      );
      if (seq == null) {
        throw StateError(
          'Maximum customer IDs reached (${formatCustomerId(maxCustomerIdSequence)}).',
        );
      }

      if (available.isNotEmpty && available.first == seq) {
        available = available.sublist(1);
      }

      final payload = <String, dynamic>{
        'current': seq > current ? seq : current,
        'available': available,
      };
      final companyRef = TenantContext.instance.writeCompanyRef;
      if (companyRef != null) {
        payload['comR'] = companyRef;
      }
      tx.set(counterRef, payload, SetOptions(merge: true));
      return formatCustomerId(seq);
    });
  }

  /// Returns a deleted customer's public ID to the reusable pool.
  static Future<void> releaseCustomerId(String customerId) async {
    final sequence = parseCustomerIdSequence(customerId);
    if (sequence == null) {
      return;
    }

    final counterRef = _counterRef(customerCounterId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(counterRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final available = List<int>.from(
        (data['available'] as List?)
                ?.map((value) => (value as num).toInt()) ??
            const [],
      );
      tx.set(
        counterRef,
        {
          'available': addReleasedCustomerSequence(available, sequence),
        },
        SetOptions(merge: true),
      );
    });
  }

  static Future<int> _incrementFixedCounter(String counterDocId) {
    final counterRef = _counterRef(counterDocId);

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

  static Future<int> _incrementCounter(
    String channel, {
    required String period,
  }) =>
      _incrementFixedCounter(counterDocId(channel, period: period));
}
