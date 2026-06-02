import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/counter_record.dart';
import '/backend/tenant_context.dart';

/// Generates sequential order IDs via Firestore counter transactions (per tenant).
class OrderIdService {
  static const _deliverySuffix = 'delivery';
  static const _retailSuffix = 'retail';

  static DocumentReference _counterRef(String suffix) {
    final companyId =
        TenantContext.instance.activeCompanyRef?.id ?? 'default';
    return CounterRecord.collection.doc('${companyId}_$suffix');
  }

  static Future<String> nextDeliveryOrderId() async {
    final year = DateTime.now().year;
    final seq = await _incrementSharedCounter();
    return 'TFG-$year-${seq.toString().padLeft(4, '0')}';
  }

  static Future<String> nextRetailOrderId() async {
    final seq = await _incrementSharedCounter();
    return 'TFG-WI${seq.toString().padLeft(4, '0')}';
  }

  /// Delivery and retail share one sequence; both counter docs stay in sync.
  static Future<int> _incrementSharedCounter() {
    final deliveryRef = _counterRef(_deliverySuffix);
    final retailRef = _counterRef(_retailSuffix);

    return FirebaseFirestore.instance.runTransaction((tx) async {
      final deliverySnap = await tx.get(deliveryRef);
      final retailSnap = await tx.get(retailRef);

      final deliveryData =
          deliverySnap.data() as Map<String, dynamic>?;
      final deliveryCurrent = deliverySnap.exists
          ? (deliveryData?['current'] as num?)?.toInt() ?? 0
          : 0;

      final retailData = retailSnap.data() as Map<String, dynamic>?;
      final retailCurrent = retailSnap.exists
          ? (retailData?['current'] as num?)?.toInt() ?? 0
          : 0;
      final current =
          deliveryCurrent > retailCurrent ? deliveryCurrent : retailCurrent;
      final next = current + 1;

      final payload = {'current': next};
      tx.set(deliveryRef, payload, SetOptions(merge: true));
      tx.set(retailRef, payload, SetOptions(merge: true));
      return next;
    });
  }
}
