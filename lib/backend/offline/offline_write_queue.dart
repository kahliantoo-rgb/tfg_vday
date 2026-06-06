import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '/backend/observability/app_logger.dart';

enum OfflineOperationType {
  createDraftOrder,
}

/// Local queue for critical writes when Firestore is unreachable.
/// Complements paper fallback — staff can keep serving; app syncs on reconnect.
class OfflineWriteQueue {
  OfflineWriteQueue._();

  static const _storageKey = 'offline_write_queue_v1';
  static final OfflineWriteQueue instance = OfflineWriteQueue._();

  Future<List<OfflineWriteItem>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    return raw
        .map((line) => OfflineWriteItem.fromJson(
              Map<String, dynamic>.from(jsonDecode(line) as Map),
            ))
        .toList();
  }

  Future<void> _save(List<OfflineWriteItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      items.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<int> pendingCount() async => (await _load()).length;

  Future<String> enqueueCreateDraftOrder({
    required String uid,
    required String companyId,
    required String companyPath,
  }) async {
    final items = await _load();
    final id = const Uuid().v4();
    items.add(
      OfflineWriteItem(
        id: id,
        type: OfflineOperationType.createDraftOrder,
        payload: {
          'uid': uid,
          'companyId': companyId,
          'companyPath': companyPath,
        },
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await _save(items);
    AppLogger.warn(
      'Queued offline createDraftOrder',
      context: {'queueId': id, 'companyId': companyId},
    );
    return id;
  }

  /// Processes queued items with [handler]. Returns number successfully flushed.
  Future<int> flush(
    Future<bool> Function(OfflineWriteItem item) handler,
  ) async {
    final items = await _load();
    if (items.isEmpty) {
      return 0;
    }

    var flushed = 0;
    final remaining = <OfflineWriteItem>[];

    for (final item in items) {
      try {
        final ok = await handler(item);
        if (ok) {
          flushed++;
        } else {
          item.retryCount++;
          remaining.add(item);
        }
      } catch (error, stackTrace) {
        item.retryCount++;
        remaining.add(item);
        AppLogger.error(
          'Offline queue flush failed',
          error: error,
          stackTrace: stackTrace,
          context: {'queueId': item.id, 'type': item.type.name},
        );
      }
    }

    await _save(remaining);
    if (flushed > 0) {
      AppLogger.info('Offline queue flushed', context: {'count': flushed});
    }
    return flushed;
  }
}

class OfflineWriteItem {
  OfflineWriteItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  final String id;
  final OfflineOperationType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory OfflineWriteItem.fromJson(Map<String, dynamic> json) {
    return OfflineWriteItem(
      id: json['id'] as String,
      type: OfflineOperationType.values.byName(json['type'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
    );
  }
}
