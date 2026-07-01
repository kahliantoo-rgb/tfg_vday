import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/operation_reminder_copy.dart';

void main() {
  group('buildTomorrowPrepNoticeBody', () {
    test('no delivery', () {
      expect(
        buildTomorrowPrepNoticeBody(deliveryCount: 0, pendingCount: 0),
        'No deliveries scheduled for tomorrow.',
      );
    });

    test('one delivery pending', () {
      expect(
        buildTomorrowPrepNoticeBody(deliveryCount: 1, pendingCount: 1),
        '1 delivery scheduled\n1 order pending preparation',
      );
    });

    test('multiple deliveries pending', () {
      expect(
        buildTomorrowPrepNoticeBody(deliveryCount: 8, pendingCount: 3),
        '8 deliveries scheduled\n3 orders pending preparation',
      );
    });

    test('all ready', () {
      expect(
        buildTomorrowPrepNoticeBody(deliveryCount: 8, pendingCount: 0),
        '8 deliveries scheduled\nAll orders are ready.',
      );
    });
  });
}
