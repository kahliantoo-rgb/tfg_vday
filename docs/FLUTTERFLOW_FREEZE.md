# FlutterFlow freeze policy (Strategy A)

**Status:** active · **Effective:** 2026-06-05

This repository is the **single source of truth** for TFG VDAY. FlutterFlow is **not** used for code export or deployment.

---

## Policy

| Rule | Detail |
|------|--------|
| **No re-export** | Do not push / download code from FlutterFlow into this repo |
| **Edit here only** | All changes go through Git → PR → CI → deploy |
| **UI changes** | Edit `*_widget.dart` in Cursor/IDE; do not re-import whole project from FF |
| **New features** | Add Dart under `lib/backend/`, `lib/custom_code/`, `lib/components/`, or page widgets |
| **Deploy** | `flutter build` + `firebase deploy` (see [README](../README.md)) |

### In FlutterFlow (console)

1. Mark the project **“exported — maintenance in Git only”** (team note).
2. Do **not** use “Push to GitHub” or “Download code” to overwrite this repo.
3. FF may still be used as a **visual reference** or for one-off design mockups — never as code source.

---

## What to keep vs change

### Keep (custom business logic — do not lose)

| Path | Why |
|------|-----|
| `lib/backend/*_helpers.dart`, `*_service.dart` | Order flow, tenant, reports, CSV — **67 unit tests** |
| `lib/auth/role_*.dart`, `tenant_context.dart` | Roles, driver guard, multi-company |
| `lib/custom_code/` | Bluetooth, PDF, CSV exports |
| `lib/flutter_flow/nav/nav.dart` | Custom role routing (not stock FF) |
| `firebase/` | Rules, scripts, `verify:peak`, CI tests |

### Safe to edit (UI shell)

| Path | Notes |
|------|-------|
| `lib/pages/*/*_widget.dart` | Large FF-generated screens — refactor incrementally |
| `lib/components/*` | Shared UI |
| `lib/flutter_flow/flutter_flow_theme.dart` | Theme tokens |

### Do not bulk-delete yet

`lib/flutter_flow/` is still required at runtime (theme, router, widgets). Removing it is **Phase 1+** of decoupling, not Strategy A.

---

## Protected files (integrity check)

CI runs `scripts/check_custom_integrity.sh` to ensure a mistaken FF re-export did not wipe custom logic. Each file must contain its marker string:

| File | Marker |
|------|--------|
| `lib/flutter_flow/nav/nav.dart` | `role_route_guard` |
| `lib/auth/role_route_guard.dart` | `kDriverAllowedRoutePaths` |
| `lib/backend/tenant_context.dart` | `class TenantContext` |
| `lib/backend/order_id_service.dart` | `OrderIdService` |
| `lib/backend/order_status_helpers.dart` | `createOrderStatusUpdateData` |
| `lib/backend/order_delete_service.dart` | `deleted_orders` |
| `lib/custom_code/bluetooth_receipt_printer.dart` | `ESC/POS` |
| `lib/custom_code/delivery_order_pdf_printer.dart` | `INVOICE` |
| `firebase/firestore.rules` | `docBelongsToAuthTenant` |

If CI fails: **stop merge** — compare diff against `main`; restore custom files from Git history.

---

## Workflow for developers

```
1. git pull main
2. Edit Dart in lib/ (or firebase/)
3. `flutter test`          # expect 67 passed
4. `scripts/check_custom_integrity.ps1` (Windows) or `bash scripts/check_custom_integrity.sh` (macOS/Linux)
5. `cd firebase && npm run test:firebase`   # optional locally (needs Java 21)
6. PR → CI green → merge
7. Deploy: `flutter build web/apk` → `firebase deploy` (see README)
```

**Never:**

- Paste a full FlutterFlow zip over the repo
- Re-export and commit without reviewing `nav.dart`, `auth/`, `backend/*_helpers.dart`

---

## If UI must change quickly (peak season)

1. Prefer small edits in the existing `*_widget.dart`.
2. Extract new logic into `lib/backend/` or `lib/components/` (testable).
3. Run `flutter test` before deploy.
4. Log manual smoke in [SMOKE_TEST_LOG.md](SMOKE_TEST_LOG.md).

---

## Later (optional, post-peak)

Strategy A does **not** require immediate renames. When ready:

- Rename `flutter_flow/` → `app_core/` (imports only)
- Split large widgets (see CTO decoupling notes)
- Riverpod / repository layer — only if long-term platform

---

## Related docs

- [WORKFLOW.md](WORKFLOW.md) — system design
- [SMOKE_TEST_LOG.md](SMOKE_TEST_LOG.md) — verification
- [RUNBOOK_PEAK_OPERATIONS.zh.md](RUNBOOK_PEAK_OPERATIONS.zh.md) — on-call
