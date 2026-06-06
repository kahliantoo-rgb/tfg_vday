import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tfg_vday/backend/offline/offline_write_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('enqueueCreateDraftOrder increases pending count', () async {
    final queue = OfflineWriteQueue.instance;

    expect(await queue.pendingCount(), 0);

    await queue.enqueueCreateDraftOrder(
      uid: 'uid1',
      companyId: 'acme',
      companyPath: 'Companies/acme',
    );

    expect(await queue.pendingCount(), 1);
  });

  test('flush removes successfully handled items', () async {
    final queue = OfflineWriteQueue.instance;

    await queue.enqueueCreateDraftOrder(
      uid: 'uid1',
      companyId: 'acme',
      companyPath: 'Companies/acme',
    );

    final flushed = await queue.flush((item) async => true);
    expect(flushed, 1);
    expect(await queue.pendingCount(), 0);
  });

  test('flush keeps failed items for retry', () async {
    final queue = OfflineWriteQueue.instance;

    await queue.enqueueCreateDraftOrder(
      uid: 'uid1',
      companyId: 'acme',
      companyPath: 'Companies/acme',
    );

    final flushed = await queue.flush((item) async => false);
    expect(flushed, 0);
    expect(await queue.pendingCount(), 1);
  });
}
