/// Named traces and p95 targets for Firebase Performance monitoring.
///
/// Review in Firebase Console → Performance after peak rehearsal.
/// See docs/OBSERVABILITY.md for full baseline table.
class PerformanceBaselines {
  PerformanceBaselines._();

  static const traceCreateDraftOrder = 'create_draft_order';
  static const traceNextDeliveryOrderId = 'next_delivery_order_id';
  static const traceOfflineQueueFlush = 'offline_queue_flush';

  /// Target p95 durations (milliseconds) — alert if exceeded in rehearsal.
  static const Map<String, int> p95Ms = {
    traceCreateDraftOrder: 3000,
    traceNextDeliveryOrderId: 1500,
    traceOfflineQueueFlush: 5000,
  };
}
