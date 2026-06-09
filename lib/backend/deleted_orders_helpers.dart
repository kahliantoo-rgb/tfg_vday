import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/deleted_orders_record.dart';
import '/backend/schema/enums/enums.dart';

const int kDeletedOrdersPageSize = 20;

const kDeletedOrderStatusFilterOptions = <String>[
  'All',
  'pending',
  'processing',
  'ready_to_delivery',
  'out_of_delivery',
  'completed',
  'cancelled',
];

/// Active archives only — excludes restored orders from the dashboard list.
List<DeletedOrdersRecord> activeDeletedOrders(
  List<DeletedOrdersRecord> records,
) =>
    records.where((record) => !record.isRestored).toList(growable: false);

String deletedOrderCustomerName(DeletedOrdersRecord record) {
  final data = record.orderData;
  final client = (data['client_name'] as String?)?.trim();
  if (client != null && client.isNotEmpty) {
    return client;
  }
  final recipient = (data['recipient_name'] as String?)?.trim();
  if (recipient != null && recipient.isNotEmpty) {
    return recipient;
  }
  return '—';
}

DateTime? deletedOrderCreatedTime(DeletedOrdersRecord record) {
  final value = record.orderData['created_time'];
  if (value is DateTime) {
    return value;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

double deletedOrderTotalAmount(DeletedOrdersRecord record) {
  final data = record.orderData;
  final totalAmount = data['totalAmount'];
  if (totalAmount is num) {
    return totalAmount.toDouble();
  }
  final total = data['total'];
  if (total is num) {
    return total.toDouble();
  }
  return 0.0;
}

String deletedOrderStatusLabel(DeletedOrdersRecord record) {
  if (record.originalOrderStatus.isNotEmpty) {
    return record.originalOrderStatus;
  }
  final status = record.orderData['status'];
  if (status is String && status.isNotEmpty) {
    return status;
  }
  if (status is OrderStatus) {
    return status.name;
  }
  final legacy = record.orderData['orderstatus'];
  if (legacy is String && legacy.isNotEmpty) {
    return legacy;
  }
  return '—';
}

String formatDeletedOrderDate(DateTime? date) {
  if (date == null) {
    return '—';
  }
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String formatDeletedOrderDateTime(DateTime? date) {
  if (date == null) {
    return '—';
  }
  return '${formatDeletedOrderDate(date)} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

bool deletedOrderMatchesDateRange(
  DeletedOrdersRecord record, {
  DateTime? from,
  DateTime? to,
}) {
  final deletedAt = record.deletedAt;
  if (deletedAt == null) {
    return from == null && to == null;
  }
  if (from != null) {
    final start = DateTime(from.year, from.month, from.day);
    if (deletedAt.isBefore(start)) {
      return false;
    }
  }
  if (to != null) {
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    if (deletedAt.isAfter(end)) {
      return false;
    }
  }
  return true;
}

bool deletedOrderMatchesSearch(DeletedOrdersRecord record, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  if (record.orderId.toLowerCase().contains(normalized)) {
    return true;
  }
  if (record.originalOrderId.toLowerCase().contains(normalized)) {
    return true;
  }
  return deletedOrderCustomerName(record).toLowerCase().contains(normalized);
}

bool deletedOrderMatchesStatusFilter(
  DeletedOrdersRecord record,
  String statusFilter,
) {
  if (statusFilter == 'All' || statusFilter.isEmpty) {
    return true;
  }
  final status = deletedOrderStatusLabel(record).toLowerCase();
  final filter = statusFilter.toLowerCase();
  if (status == filter) {
    return true;
  }
  // Legacy label compatibility.
  if (filter == 'ready_to_delivery' && status == 'readytoship') {
    return true;
  }
  if (filter == 'out_of_delivery' && status == 'outofdelivery') {
    return true;
  }
  return false;
}

bool deletedOrderMatchesDeletedByFilter(
  DeletedOrdersRecord record,
  String? deletedByEmail,
) {
  if (deletedByEmail == null || deletedByEmail.isEmpty || deletedByEmail == 'All') {
    return true;
  }
  return record.deletedByEmail.toLowerCase() == deletedByEmail.toLowerCase();
}

List<DeletedOrdersRecord> filterDeletedOrders({
  required List<DeletedOrdersRecord> records,
  String searchQuery = '',
  DateTime? deletedFrom,
  DateTime? deletedTo,
  String? deletedByEmail,
  String statusFilter = 'All',
  bool includeRestored = false,
}) {
  var filtered = includeRestored ? records : activeDeletedOrders(records);
  filtered = filtered
      .where((record) => deletedOrderMatchesSearch(record, searchQuery))
      .where(
        (record) => deletedOrderMatchesDateRange(
          record,
          from: deletedFrom,
          to: deletedTo,
        ),
      )
      .where((record) => deletedOrderMatchesDeletedByFilter(record, deletedByEmail))
      .where((record) => deletedOrderMatchesStatusFilter(record, statusFilter))
      .toList(growable: false);

  filtered.sort((a, b) {
    final aTime = a.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });
  return filtered;
}

List<String> uniqueDeletedByEmails(List<DeletedOrdersRecord> records) {
  final emails = records
      .map((record) => record.deletedByEmail.trim())
      .where((email) => email.isNotEmpty)
      .toSet()
      .toList(growable: false);
  emails.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return emails;
}

class DeletedOrdersPageSlice {
  const DeletedOrdersPageSlice({
    required this.items,
    required this.pageIndex,
    required this.totalPages,
    required this.totalItems,
  });

  final List<DeletedOrdersRecord> items;
  final int pageIndex;
  final int totalPages;
  final int totalItems;
}

DeletedOrdersPageSlice paginateDeletedOrders({
  required List<DeletedOrdersRecord> records,
  required int pageIndex,
  int pageSize = kDeletedOrdersPageSize,
}) {
  if (records.isEmpty) {
    return const DeletedOrdersPageSlice(
      items: [],
      pageIndex: 0,
      totalPages: 1,
      totalItems: 0,
    );
  }
  final totalPages = (records.length / pageSize).ceil().clamp(1, 999999);
  final safePage = pageIndex.clamp(0, totalPages - 1);
  final start = safePage * pageSize;
  final end = (start + pageSize).clamp(0, records.length);
  return DeletedOrdersPageSlice(
    items: records.sublist(start, end),
    pageIndex: safePage,
    totalPages: totalPages,
    totalItems: records.length,
  );
}

class DeletedOrdersAnalytics {
  const DeletedOrdersAnalytics({
    required this.totalDeletedOrders,
    required this.totalDeletedRevenue,
    required this.mostDeletedProduct,
    required this.mostActiveDeleter,
  });

  final int totalDeletedOrders;
  final double totalDeletedRevenue;
  final String mostDeletedProduct;
  final String mostActiveDeleter;
}

DeletedOrdersAnalytics computeDeletedOrdersAnalytics(
  List<DeletedOrdersRecord> records,
) {
  final active = activeDeletedOrders(records);
  final productCounts = <String, int>{};
  final deleterCounts = <String, int>{};
  var revenue = 0.0;

  for (final record in active) {
    revenue += deletedOrderTotalAmount(record);
    final deleter = record.deletedByEmail.trim();
    if (deleter.isNotEmpty) {
      deleterCounts[deleter] = (deleterCounts[deleter] ?? 0) + 1;
    }
    for (final raw in record.orderItems) {
      if (raw is! Map) {
        continue;
      }
      final itemData = raw['item_data'];
      if (itemData is! Map) {
        continue;
      }
      final name = (itemData['name'] as String?)?.trim();
      if (name == null || name.isEmpty) {
        continue;
      }
      final qty = itemData['qty'];
      final count = qty is num ? qty.toInt().clamp(1, 9999) : 1;
      productCounts[name] = (productCounts[name] ?? 0) + count;
    }
  }

  return DeletedOrdersAnalytics(
    totalDeletedOrders: active.length,
    totalDeletedRevenue: revenue,
    mostDeletedProduct: _topKey(productCounts) ?? '—',
    mostActiveDeleter: _topKey(deleterCounts) ?? '—',
  );
}

String? _topKey(Map<String, int> counts) {
  if (counts.isEmpty) {
    return null;
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.first.key;
}

String activityLogActionLabel(String action) {
  switch (action) {
    case 'deleted':
      return 'Deleted';
    case 'restored':
      return 'Restored';
    case 'permanently_deleted':
      return 'Permanently deleted';
    default:
      return action;
  }
}

DateTime? activityLogEntryTime(Map<String, dynamic> entry) {
  final value = entry['at'];
  if (value is DateTime) {
    return value;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

List<Map<String, dynamic>> sortedActivityLogEntries(
  List<dynamic> activityLog,
) {
  final entries = activityLog
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList(growable: false);
  entries.sort((a, b) {
    final aTime = activityLogEntryTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = activityLogEntryTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });
  return entries;
}
