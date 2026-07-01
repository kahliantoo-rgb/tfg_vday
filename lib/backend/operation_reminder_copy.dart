import 'package:flutter/widgets.dart';

import '/l10n/app_strings.dart';
import '/l10n/locale_text.dart';

/// Deep-link target for staff notice taps (stored in Firestore / FCM payload).
abstract final class StaffNoticeNavTarget {
  static const tomorrowPreparation = 'tomorrow_preparation';
}

const staffNoticeNavPayloadPrefix = 'nav:';

String encodeStaffNoticeNavPayload(String navTarget) =>
    '$staffNoticeNavPayloadPrefix$navTarget';

String? decodeStaffNoticeNavTarget(String? payload) {
  if (payload == null || payload.isEmpty) {
    return null;
  }
  if (!payload.startsWith(staffNoticeNavPayloadPrefix)) {
    return null;
  }
  final target = payload.substring(staffNoticeNavPayloadPrefix.length).trim();
  return target.isEmpty ? null : target;
}

String _localized(
  BuildContext? context,
  String key, {
  Map<String, String> params = const {},
  required String englishFallback,
}) {
  if (context == null) {
    var text = englishFallback;
    for (final entry in params.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }
  final lang = currentLanguageCode(context);
  final entry = kAppStrings[key];
  var text = entry?[lang] ?? entry?['en'] ?? englishFallback;
  for (final entry in params.entries) {
    text = text.replaceAll('{${entry.key}}', entry.value);
  }
  return text;
}

/// Tomorrow prep notice title — localized when [context] is available.
String tomorrowPrepNoticeTitle([BuildContext? context]) => _localized(
      context,
      'notice.tomorrowPrep.title',
      englishFallback: "Tomorrow's Preparation",
    );

/// Builds tomorrow prep body from stored counts (i18n-ready).
String buildTomorrowPrepNoticeBody({
  required int deliveryCount,
  required int pendingCount,
  BuildContext? context,
}) {
  if (deliveryCount == 0) {
    return _localized(
      context,
      'notice.tomorrowPrep.noDelivery',
      englishFallback: 'No deliveries scheduled for tomorrow.',
    );
  }

  final line1 = deliveryCount == 1
      ? _localized(
          context,
          'notice.tomorrowPrep.oneDeliveryScheduled',
          englishFallback: '1 delivery scheduled',
        )
      : _localized(
          context,
          'notice.tomorrowPrep.deliveriesScheduled',
          params: {'count': '$deliveryCount'},
          englishFallback: '$deliveryCount deliveries scheduled',
        );

  final line2 = pendingCount == 0
      ? _localized(
          context,
          'notice.tomorrowPrep.allReady',
          englishFallback: 'All orders are ready.',
        )
      : pendingCount == 1
          ? _localized(
              context,
              'notice.tomorrowPrep.oneOrderPending',
              englishFallback: '1 order pending preparation',
            )
          : _localized(
              context,
              'notice.tomorrowPrep.ordersPending',
              params: {'count': '$pendingCount'},
              englishFallback: '$pendingCount orders pending preparation',
            );

  return '$line1\n$line2';
}
