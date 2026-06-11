import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/staff_notice_helpers.dart';

void main() {
  group('staff notice recipients', () {
    test('operations leadership and florists receive order created notices', () {
      expect(receivesOrderCreatedNotices(UserRole.admin), isTrue);
      expect(receivesOrderCreatedNotices(UserRole.director), isTrue);
      expect(receivesOrderCreatedNotices(UserRole.manager), isTrue);
      expect(receivesOrderCreatedNotices(UserRole.senior_florist), isTrue);
      expect(receivesOrderCreatedNotices(UserRole.florist), isTrue);
      expect(receivesOrderCreatedNotices(UserRole.driver), isFalse);
      expect(receivesOrderCreatedNotices(UserRole.account), isFalse);
    });
  });
}
