import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/counter_record.dart';
import '/backend/tenant_context.dart';

/// Generates sequential order IDs via Firestore counters (`{writeCompanyId}_*`).
/// Delivery (`TFG-YYYY-####`) and retail (`TFG-WI####`) use independent sequences.
class OrderIdService {
  static const _deliverySuffix = 'delivery';
  static const _retailSuffix = 'retail';

  static String get _companyId => TenantContext.instance.writeCompanyId;

  /// Counter doc id, e.g. `lc3Dhfby8f35Md0E1vZC_delivery`.
  static String counterDocId(String suffix) => '${_companyId}_$suffix';

  static DocumentReference _counterRef(String suffix) =>
      CounterRecord.collection.doc(counterDocId(suffix));

  static bool isRetailOrderId(String? orderId) =>
      orderId != null && orderId.startsWith('TFG-WI');

  static bool isDeliveryOrderId(String? orderId) {
    if (orderId == null || orderId.isEmpty) {
      return false;
    }
    return RegExp(r'^TFG-\d{4}-\d+$').hasMatch(orderId);
  }

  static Future<String> nextDeliveryOrderId() async {
    final year = DateTime.now().year;
    final seq = await _incrementCounter(_deliverySuffix);
    return 'TFG-$year-${seq.toString().padLeft(4, '0')}';
  }

  static Future<String> nextRetailOrderId() async {
    final seq = await _incrementCounter(_retailSuffix);
    return 'TFG-WI${seq.toString().padLeft(4, '0')}';
  }

  static Future<int> _incrementCounter(String suffix) {
    final counterRef = _counterRef(suffix);

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
