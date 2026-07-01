import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/l10n/locale_text.dart';

/// Stable keys for driver delivery status filter chips.
enum DriverDeliveryTabKey {
  all,
  assigned,
  outForDelivery,
  completed,
}

extension DriverDeliveryTabKeyX on DriverDeliveryTabKey {
  String label(BuildContext context) {
    switch (this) {
      case DriverDeliveryTabKey.all:
        return loc(context, en: 'All', zh: '全部', ms: 'Semua');
      case DriverDeliveryTabKey.assigned:
        return loc(context, en: 'Assigned', zh: '待派送', ms: 'Ditugaskan');
      case DriverDeliveryTabKey.outForDelivery:
        return loc(
          context,
          en: 'Out for Delivery',
          zh: '派送中',
          ms: 'Dalam Penghantaran',
        );
      case DriverDeliveryTabKey.completed:
        return loc(context, en: 'Completed', zh: '已完成', ms: 'Selesai');
    }
  }
}

DriverDeliveryTabKey? driverDeliveryTabKeyFromLabel(String? label) {
  if (label == null || label.isEmpty) {
    return null;
  }
  for (final key in DriverDeliveryTabKey.values) {
    if (_allLabelsForKey(key).contains(label)) {
      return key;
    }
  }
  return null;
}

List<String> _allLabelsForKey(DriverDeliveryTabKey key) {
  switch (key) {
    case DriverDeliveryTabKey.all:
      return const ['All', '全部', 'Semua'];
    case DriverDeliveryTabKey.assigned:
      return const ['Assigned', '待派送', 'Ditugaskan'];
    case DriverDeliveryTabKey.outForDelivery:
      return const ['Out for Delivery', '派送中', 'Dalam Penghantaran'];
    case DriverDeliveryTabKey.completed:
      return const ['Completed', '已完成', 'Selesai'];
  }
}

List<ChipData> driverDeliveryTabChipOptions(BuildContext context) {
  return DriverDeliveryTabKey.values
      .map((key) => ChipData(key.label(context)))
      .toList();
}
