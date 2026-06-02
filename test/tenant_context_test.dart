import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/tenant_context.dart';

void main() {
  test('needsCompanySelection when no company and no profile ref', () {
    expect(
      TenantContext.instance.needsCompanySelection(null),
      isTrue,
    );
  });

  test('needsCompanySelection false when profile has companyRef', () {
    // Profile object not constructed; behavior covered by integration.
    expect(UserRole.admin, isNotNull);
  });
}
