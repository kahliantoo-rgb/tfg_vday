import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/app_permissions.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/user_permissions_helpers.dart';

void main() {
  group('effectivePermissionForUser', () {
    test('user override grants permission beyond florist role default', () {
      expect(
        effectivePermissionForUser(
          role: UserRole.florist,
          permission: AppPermission.editOrderDetails,
          userOverrides: {'editOrderDetails': true},
        ),
        isTrue,
      );
    });

    test('user override can deny manager delete orders', () {
      expect(
        effectivePermissionForUser(
          role: UserRole.manager,
          permission: AppPermission.deleteOrders,
          userOverrides: {'deleteOrders': false},
        ),
        isFalse,
      );
    });

    test('falls back to role defaults when no user override', () {
      expect(
        effectivePermissionForUser(
          role: UserRole.manager,
          permission: AppPermission.editOrderDetails,
        ),
        isTrue,
      );
      expect(
        effectivePermissionForUser(
          role: UserRole.florist,
          permission: AppPermission.editOrderDetails,
        ),
        isFalse,
      );
    });
  });

  group('sanitizeUserPermissionOverrides', () {
    test('drops overrides that match role baseline', () {
      final sanitized = sanitizeUserPermissionOverrides(
        role: UserRole.florist,
        draft: {
          'editOrderDetails': true,
          'createOrders': true,
        },
      );
      expect(sanitized.containsKey('createOrders'), isFalse);
      expect(sanitized['editOrderDetails'], isTrue);
    });
  });
}
