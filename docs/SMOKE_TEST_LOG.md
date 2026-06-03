# Smoke Test Log

Execution record for [WORKFLOW.md §16](WORKFLOW.md#16-deployment-checklist-peak-season) and peak-rehearsal hand tests (P1 D1–D5).

**Environment:** Firebase project `tfg-sales-record`  
**Prerequisite:** P0 rules deployed ✅ **2026-06-03** · P1 automation added ✅ **2026-06-03**

---

## P1 automated verification (2026-06-03)

| Check | Command / test | Result | Notes |
|-------|----------------|--------|-------|
| Flutter unit tests (20) | `flutter test` | **PASS** | incl. D3 status chain, C3-2 route guard |
| Firestore rules (13 cases) | `cd firebase && npm run test:firebase` | **CI** | needs Java locally; runs on GitHub Actions |
| Counter init script | `npm run init:counters:emulator` | **CI** | integration test in `test:firebase` |
| Production counter init | `npm run init:counters` | **PASS** | 2026-06-03 — created `default_*`; company `lc3Dhfby8f35Md0E1vZC` ok |
| Production user/counter audit | `npm run verify:peak` | **PASS** | 2026-06-03 — 2 warnings resolved (tickets below) |
| Order counter + create (emulator) | `npm run test:firebase` | **CI** | `order_counter.integration.test.js` (3 cases) |

**Production counter init (run once before peak):**

```bash
cd firebase
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccount.json
npm run init:counters:dry-run
npm run init:counters
npm run verify:peak
```

---

## §16 Smoke — Summary

| # | Date | Executor | Environment (Web/Android) | Account role | Step (§16) | Result PASS/FAIL | Evidence (screenshot / order ID) | Notes |
|---|------|----------|---------------------------|--------------|------------|------------------|----------------------------------|-------|
| C1-1 | 2026-06-03 | | | staff | Deploy rules | **PASS** | | P0 tenant isolation |
| C1-2 | | | | staff | User docs + roles | **AUTO** | | `npm run verify:peak` when credentials set |
| C1-3 | | | | staff | Staff test account | **AUTO** | | verify:peak checks admin/senior_florist exists |
| C1-4 | 2026-06-03 | | | driver | Driver test account | **PASS** | `tfg.driver.smoke@gmail.com` | uid `XZvTGyTIn9Tat9a8S66y0XThYfs1` |
| C2-1 | | | Web / Android | staff | Create order | **MANUAL** | | |
| C2-2 | | | | staff | Add products | **MANUAL** | | |
| C2-3a | | | | staff | Retail branch | **MANUAL** | | |
| C2-3b | | | | staff | Delivery branch | **MANUAL** | | |
| C2-4 | | | | staff | Order list | **MANUAL** | | |
| C2-5 | | | Android | staff | Bluetooth print | **MANUAL** | | Skip on Web |
| C2-6 | | | | staff | Export CSV | **MANUAL** | | |
| C3-1 | | | Android | driver | Login → delivery page | **MANUAL** | | |
| C3-2 | 2026-06-03 | | | driver | Block staff routes | **PASS** | | unit test: `/salesDashBoard` denied |
| C3-3 | | | | driver | Advance delivery order | **MANUAL** | | |
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

---

## Manual rehearsal script (≈30 min)

1. **Staff Web:** login → create delivery order → add product → complete customer form → export CSV (D5 partial)
2. **Staff Android:** retail walk-in → thermal print (D1, D4)
3. **Driver Android:** login (must land on delivery page, not dashboard) → advance one order through status chain (C3, D3 live)
4. **Staff:** confirm order list shows driver’s status update (C3-5)

*Attach screenshots or order IDs in Evidence column above.*
