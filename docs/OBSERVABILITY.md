# Observability & performance baselines

Centralized logging and performance monitoring for peak-season diagnosis.

---

## Stack

| Layer | Tool | Where |
|-------|------|-------|
| Crashes + errors | **Firebase Crashlytics** | Android / iOS release builds |
| Performance traces | **Firebase Performance** | All platforms (web + mobile) |
| App logs | **`AppLogger`** (`lib/backend/observability/app_logger.dart`) | Debug console; Crashlytics breadcrumbs on mobile |
| Offline resilience | **`OfflineWriteQueue`** | Android / iOS — see [RUNBOOK §1](RUNBOOK_PEAK_OPERATIONS.md#1-network-outage--app-loading-forever) |

Initialization: `ObservabilityService.initialize()` in `lib/main.dart` (after `initFirebase()`).

---

## Performance baselines (p95 targets)

Measure during peak rehearsal on **staging**, then confirm on production before go-live.

| Trace name | Operation | p95 target | Code |
|------------|-----------|------------|------|
| `create_draft_order` | Full Create Order → Firestore write | **≤ 3000 ms** | `draft_order_writer.dart` |
| `next_delivery_order_id` | Counter transaction | **≤ 1500 ms** | `order_id_service.dart` |
| `offline_queue_flush` | Drain queued writes on reconnect | **≤ 5000 ms** | `offline_flush_service.dart` |

### Review in Firebase Console

1. **Performance** → filter by trace name above
2. Compare p50/p95 against targets in `performance_baselines.dart`
3. If `create_draft_order` p95 > 3 s: check Wi‑Fi, Firestore region, counter doc missing
4. If `next_delivery_order_id` p95 > 1.5 s: run `npm run verify:peak` (counter docs)

---

## Logging conventions

```dart
import '/backend/observability/app_logger.dart';

AppLogger.info('Order synced', context: {'orderId': id});
AppLogger.warn('Counter doc missing', context: {'companyId': companyId});
AppLogger.error('Payment failed', error: e, stackTrace: st);
```

| Level | Use |
|-------|-----|
| `info` | Successful business events (order created, queue flushed) |
| `warn` | Recoverable issues (offline queue, retry) |
| `error` | Failures needing investigation (sent to Crashlytics on mobile) |

**Do not** log customer PII (phone, address) in `context` maps.

---

## Crashlytics setup (release Android)

1. Enable Crashlytics in Firebase Console → `tfg-sales-record`
2. Build release APK: `flutter build apk --release`
3. Force a test crash only on a **non-production** device if needed
4. Verify crash appears in Console within ~5 minutes

Web: Crashlytics is not wired (logs go to browser console only).

---

## Offline queue (complements paper fallback)

When Create Order fails with a network error:

1. Request is stored in `SharedPreferences` (`offline_write_queue_v1`)
2. Staff sees: *"Order queued (N pending)…"*
3. On reconnect, `ConnectivityService` calls `OfflineFlushService.flushPending()`
4. Staff should still use **paper** for customer-facing slips during outage; re-enter or verify synced orders in **Order List** after recovery

Queued operations today: `createDraftOrder` only. Extend `OfflineWriteQueue` for additional write types if needed.

---

## Staging vs production telemetry

Use project **`tfg-vday-record-staging`** for rehearsal traces. See [STAGING.md](STAGING.md).
