# Smoke Test Log

Execution record for [WORKFLOW.md §16](WORKFLOW.md#16-deployment-checklist-peak-season) and peak-rehearsal hand tests (P1 D1–D5).

**Environment:** Firebase project `tfg-sales-record`  
**Prerequisite:** P0 rules deployed ✅ **2026-06-03** · P1 automation added ✅ **2026-06-03** · Web Hosting ✅ **2026-06-05**

---

## P1 automated verification

| Check | Command / test | Result | Notes |
|-------|----------------|--------|-------|
| Flutter unit tests (**67**) | `flutter test` | **PASS** | 2026-06-05 — 19 files under `test/` |
| Firestore rules + counter (emulator) | `cd firebase && npm run test:firebase` | **CI** | needs **Java** locally; runs on GitHub Actions `firestore-rules` job |
| Firestore rules only | `cd firebase && npm run test:rules` | **CI** | same Java requirement |
| Counter init script | `npm run init:counters:emulator` | **CI** | part of `test:firebase` |
| Production counter init | `npm run init:counters` | **PASS** | 2026-06-03 — `default_*`; company `lc3Dhfby8f35Md0E1vZC` ok |
| Production user/counter audit | `npm run verify:peak` | **PASS** | 2026-06-03 — warnings closed (see below) |
| CI on `main` | GitHub Actions | **PASS** | `flutter` analyze + test · `firestore-rules` · `build-apk` artifact |

**Run all Flutter tests locally:**

```bash
cd tfg_vday
flutter pub get
flutter test
# Expected: 67 passed
```

**Flutter test files (67 cases):**

| File | Focus |
|------|--------|
| `role_helpers_test.dart` | Admin / senior florist capabilities |
| `role_route_guard_test.dart` | Driver route allow-list |
| `register_user_service_test.dart` | Staff registration rules |
| `tenant_context_test.dart` | Tenant scope |
| `tenant_product_filter_test.dart` | Product tenant isolation |
| `company_search_filter_test.dart` | Company selection search |
| `order_status_helpers_test.dart` | Status chain (D3) |
| `order_list_filter_helpers_test.dart` | Order list filters |
| `order_list_display_helpers_test.dart` | Order list columns |
| `order_delete_service_test.dart` | Archive to `deleted_orders` |
| `daily_sales_report_service_test.dart` | Report + date range |
| `csv_export_alignment_test.dart` | CSV export |
| `driver_delivery_filter_helpers_test.dart` | Driver status/date filters |
| `driver_route_helpers_test.dart` | Multi-stop route |
| `user_list_helpers_test.dart` | User list + manage permissions |
| `firebase_auth_error_messages_test.dart` | Login error copy |
| `receipt_order_item_list_test.dart` | Receipt line items |
| `widget_test.dart` | Sanity |

---

## New features checklist (2026-06 — manual unless noted)

Production Web: **https://tfg-sales-record.web.app** (hard-refresh after deploy)

| # | Feature | Role | Platform | Auto | Manual smoke | Date | Result | Notes |
|---|---------|------|----------|------|--------------|------|--------|-------|
| N1 | **User List** (`/userListPage`) | admin / superadmin | Web | unit | Login → Dashboard or Company Profile → **View User List**; see Name / Role / Status | | **MANUAL** | `user_list_helpers_test.dart` |
| N2 | **Add Staff** | admin / superadmin | Web | unit | Company Profile → **Add Staff** → `/register` | | **MANUAL** | |
| N3 | **Set Inactive / Activate** | admin / superadmin | Web | unit | User List → select user → Set Inactive; inactive user cannot login | | **MANUAL** | Prefer over Delete |
| N4 | **Delete user profile** | admin / superadmin | Web | — | User List → Delete (Firestore doc only) | | **MANUAL** | Auth account remains |
| N5 | **Driver list filters** | driver | Web/APK | unit | All / Assigned / Out for Delivery / Completed + date range | | **MANUAL** | `driver_delivery_filter_helpers_test.dart` |
| N6 | **Driver suggested route** | driver | Web/APK | unit | Open Maps with multi-stop route | | **MANUAL** | |
| N7 | **Sales report date range** | staff | Web | unit | View Reports → From / To dates | | **MANUAL** | `daily_sales_report_service_test.dart` |
| N8 | **Order list select all** | staff | Web | — | Header checkbox bulk select | | **MANUAL** | |
| N9 | **Order bulk delete** | admin | Web | unit | Select orders → Delete → `deleted_orders` archive | | **MANUAL** | rules: `deleted_orders` |
| N10 | **Custom product Create dialog** | staff | Web/APK | — | Product Selection → Create → **Upload Photo** or **Add** | | **MANUAL** | `Order_item.image` optional |
| N11 | **Company Profile edit** | admin | Web | — | Logo, UEN, phone, address → Save | | **MANUAL** | |
| N12 | **PDF title INVOICE** | staff | Web | — | Print PDF → title INVOICE | | **MANUAL** | |
| N13 | **Deploy Web + rules** | tech | — | CI partial | `firebase deploy --only hosting,firestore:rules` | 2026-06-05 | **PASS** | See README deploy section |

---

## §16 Smoke — Summary

| # | Date | Executor | Environment (Web/Android) | Account role | Step (§16) | Result PASS/FAIL | Evidence (screenshot / order ID) | Notes |
|---|------|----------|---------------------------|--------------|------------|------------------|----------------------------------|-------|
| C1-1 | 2026-06-03 | | | staff | Deploy rules | **PASS** | | P0 tenant isolation |
| C1-1b | 2026-06-05 | | | staff | Deploy hosting | **PASS** | tfg-sales-record.web.app | |
| C1-2 | | | | staff | User docs + roles | **AUTO** | | `npm run verify:peak` when credentials set |
| C1-3 | | | | staff | Staff test account | **AUTO** | | verify:peak checks admin/senior_florist exists |
| C1-4 | 2026-06-03 | | | driver | Driver test account | **PASS** | `tfg.driver.smoke@gmail.com` | uid `XZvTGyTIn9Tat9a8S66y0XThYfs1` |
| C2-1 | | | Web / Android | staff | Create order | **MANUAL** | | |
| C2-2 | | | | staff | Add products | **MANUAL** | | incl. custom product N10 |
| C2-3a | | | | staff | Retail branch | **MANUAL** | | |
| C2-3b | | | | staff | Delivery branch | **MANUAL** | | |
| C2-4 | | | | staff | Order list | **MANUAL** | | N8 bulk select |
| C2-5 | | | Android | staff | Bluetooth print | **MANUAL** | | Skip on Web |
| C2-6 | | | | staff | Export CSV | **MANUAL** | | |
| C2-7 | | | Web | admin | User List / staff admin | **MANUAL** | | N1–N4 |
| C3-1 | | | Android | driver | Login → delivery page | **MANUAL** | | |
| C3-2 | 2026-06-03 | | | driver | Block staff routes | **PASS** | | unit test: `/salesDashBoard` denied |
| C3-3 | | | | driver | Advance delivery order | **MANUAL** | | N5 filters |
| C3-4 | | | | driver | Firestore field check | **MANUAL** | | rules test covers status-only update |
| C3-5 | | | | staff | Staff sees driver update | **MANUAL** | | |
| C4-1 | | | Android | staff | Manifest permissions | **MANUAL** | | |
| C4-2 | | | Android | staff | Pair + print receipt | **MANUAL** | | |

---

## Rules regression (automated in `npm run test:firebase`)

| Role | Operation | Expected | Date tested | PASS/FAIL | Notes |
|------|-----------|----------|-------------|-----------|-------|
| driver | `orders/{otherCompany}` read | **Deny** | 2026-06-03 | **PASS** | `firestore.rules.test.js` |
| driver | `orders/{ownCompany}` status update | Allow | 2026-06-03 | **PASS** | `firestore.rules.test.js` |
| driver | `counter/{otherCompany}_delivery` read | **Deny** | 2026-06-03 | **PASS** | `firestore.rules.test.js` |
| driver | `counter/{ownCompany}_delivery` read | Allow | 2026-06-03 | **PASS** | `firestore.rules.test.js` |
| driver | `audit_logs` create | **Deny** | 2026-06-03 | **PASS** | `firestore.rules.test.js` |
| driver | `counters/{x}` read | **Deny** | 2026-06-03 | **PASS** | `firestore.rules.test.js` |
| senior_florist | `counter/{id}_delivery` update | Allow | 2026-06-03 | **PASS** | `firestore.rules.test.js` |
| senior_florist | `audit_logs` create | Allow | 2026-06-03 | **PASS** | `firestore.rules.test.js` |
| platform admin | `deleted_orders` create | Allow | 2026-06-05 | **CI** | rules deploy 2026-06-05 |

---

## Counter initialization (per active company)

Run `npm run init:counters` (production) or fill after dry-run output.

| Company doc ID | `_delivery` current | `_retail` current | Verified after test order | Date | Notes |
|----------------|---------------------|-------------------|---------------------------|------|-------|
| lc3Dhfby8f35Md0E1vZC | 0 | 0 | | 2026-06-03 | init_counters PASS |
| default | 0 | 0 | | 2026-06-03 | created by init_counters |

Document IDs: `{companyDocId}_delivery` and `{companyDocId}_retail` in collection `counter`.  
If no company selected in app: `default_delivery` / `default_retail`.

---

## Peak rehearsal — Key paths (D1–D5)

| ID | Date | Executor | Platform | Path | Result | Order ID / evidence | Notes |
|----|------|----------|----------|------|--------|---------------------|-------|
| D1 | | | Android | Retail full flow (§3) | **MANUAL** | | WI format, counter sync |
| D2 | | | | Delivery full flow (§4) | **MANUAL** | | pending, address, PDF |
| D3 | 2026-06-03 | | unit test | Status chain | **PASS** | | `order_status_helpers_test.dart` |
| D4 | | | Android | Bluetooth print (3 screens) | **MANUAL** | | MAC, permissions |
| D5 | | | Web/Android | CSV export | **MANUAL** | | tenant + date filter |

---

## verify:peak warnings (2026-06-03 → closed)

`npm run verify:peak` exits **0** on errors only; these **warn** findings were logged and remediated:

| Code | Message | Resolution | Ticket | Status |
|------|---------|------------|--------|--------|
| `USER_UID_MISMATCH` | `users/{docId}` where `data.uid !== docId` (rules read `users/{auth.uid}`) | `npm run fix:user-ids` — migrated `yanyitoo1025@gmail.com` → `users/tFlQ4rhmVlhUqTjkGorHjZUhoQP2` | **peak-warn-001** | **closed** 2026-06-03 |
| `NO_DRIVER_ACCOUNT` | No `role: driver` user for §17 smoke | `npm run create:driver` — `tfg.driver.smoke@gmail.com` → `users/XZvTGyTIn9Tat9a8S66y0XThYfs1` | **peak-warn-002** | **closed** 2026-06-03 |

**Re-verify (optional):** with service account set, `npm run verify:peak` — expect `findings` with no `warn` entries (or only new drift).

---

## Known issues / tickets

| Date | ID / link | Severity | Description | Status |
|------|-----------|----------|-------------|--------|
| 2026-06-03 | create:driver | done | Smoke driver `tfg.driver.smoke@gmail.com` → `users/XZvTGyTIn9Tat9a8S66y0XThYfs1` | closed |
| 2026-06-03 | fix:user-ids | fixed | Migrated `yanyitoo1025@gmail.com` from `users/gXOBFoMVqtbglOOoSq5w` → `users/tFlQ4rhmVlhUqTjkGorHjZUhoQP2` | closed |
| 2026-06-03 | peak-warn-001 | warn | `verify:peak` → `USER_UID_MISMATCH` | closed — see table above |
| 2026-06-03 | peak-warn-002 | warn | `verify:peak` → `NO_DRIVER_ACCOUNT` | closed — see table above |
| — | local-java | info | `npm run test:rules` needs **JDK 21+** on PATH (firebase-tools) | use CI or install Temurin 21 |

---

## Manual rehearsal script (≈30 min)

1. **Staff Web:** login → create delivery order → add catalog product → **custom product** (Upload Photo + Add) → complete customer form → **View Reports** date range (N7) → export CSV (D5 partial)
2. **Admin Web:** **User List** (N1) → verify staff → **Add Staff** (N2) if needed
3. **Staff Android:** retail walk-in → thermal print (D1, D4)
4. **Driver Android/Web:** login (delivery page only) → filter chips + date (N5) → advance one order (C3, D3 live) → optional Maps route (N6)
5. **Staff:** order list bulk select (N8) → confirm driver status on order detail (C3-5)

*Attach screenshots or order IDs in Evidence columns above.*

**Production counter init (run once before peak):**

```bash
cd firebase
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccount.json
npm run init:counters:dry-run
npm run init:counters
npm run verify:peak
```
