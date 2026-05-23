import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/counter_record.dart';

/// Generates sequential order IDs via Firestore counter transactions.
class OrderIdService {
  static const _deliveryCounterId = 'delivery';
  static const _retailCounterId = 'retail';

  static Future<String> nextDeliveryOrderId() async {
    final year = DateTime.now().year;
    final seq = await _incrementCounter(
      CounterRecord.collection.doc(_deliveryCounterId),
    );
    return 'TFG-$year-${seq.toString().padLeft(4, '0')}';
  }

  static Future<String> nextRetailOrderId() async {
    final seq = await _incrementCounter(
      CounterRecord.collection.doc(_retailCounterId),
    );
    return 'TFG-WI${seq.toString().padLeft(4, '0')}';
  }

  static Future<int> _incrementCounter(DocumentReference counterRef) {
    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(counterRef);
      final current = snap.exists
          ? (snap.data()?['current'] as num?)?.toInt() ?? 0
          : 0;
      final next = current + 1;
      tx.set(
        counterRef,
        {'current': next},
        SetOptions(merge: true),
      );
      return next;
    });
  }
}
