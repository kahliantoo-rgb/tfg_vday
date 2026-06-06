import '/backend/draft_order_writer.dart';
import '/backend/observability/observability_service.dart';
import '/backend/observability/performance_baselines.dart';
import '/backend/offline/offline_write_queue.dart';

/// Drains the offline queue when connectivity returns.
class OfflineFlushService {
  OfflineFlushService._();

  static final OfflineFlushService instance = OfflineFlushService._();
  bool _flushing = false;

  Future<int> flushPending() {
    return ObservabilityService.trace(
      PerformanceBaselines.traceOfflineQueueFlush,
      _flushPending,
    );
  }

  Future<int> _flushPending() async {
    if (_flushing) {
      return 0;
    }
    _flushing = true;
    try {
      return await OfflineWriteQueue.instance.flush(_handleItem);
    } finally {
      _flushing = false;
    }
  }

  Future<bool> _handleItem(OfflineWriteItem item) async {
    switch (item.type) {
      case OfflineOperationType.createDraftOrder:
        return syncQueuedDraftOrder(item);
    }
  }
}
