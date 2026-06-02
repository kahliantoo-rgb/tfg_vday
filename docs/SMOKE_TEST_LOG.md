# Smoke Test Log

Execution record for [WORKFLOW.md §16](WORKFLOW.md#16-deployment-checklist-peak-season) and peak-rehearsal hand tests (P1 D1–D5).

**Environment:** Firebase project `tfg-sales-record`  
**Prerequisite:** P0 green (`flutter analyze`, `flutter test`, CI) · Firestore rules deployed from `firebase/firestore.rules`

---

## §16 Smoke — Summary

| # | Date | Executor | Environment (Web/Android) | Account role | Step (§16) | Result PASS/FAIL | Evidence (screenshot / order ID) | Notes |
|---|------|----------|---------------------------|--------------|------------|------------------|----------------------------------|-------|
| C1-1 | | | | staff | Deploy rules | | | `firebase deploy --only firestore:rules` |
| C1-2 | | | | staff | User docs + roles | | | `users/{uid}.role` correct |
| C1-3 | | | | staff | Staff test account | | | admin or senior_florist |
| C1-4 | | | | driver | Driver test account | | | role = driver |
| C2-1 | | | Web / Android | staff | Create order | | | `orderId` like `TFG-YYYY-####` |
| C2-2 | | | | staff | Add products | | | `Order_item` rows |
| C2-3a | | | | staff | Retail branch | | | `TFG-WI####`, completed |
| C2-3b | | | | staff | Delivery branch | | | `orderType=Delivery`, pending |
| C2-4 | | | | staff | Order list | | | Both orders visible |
| C2-5 | | | Android | staff | Bluetooth print | | | Skip on Web |
| C2-6 | | | | staff | Export CSV | | | Row count matches filter |
| C3-1 | | | Android | driver | Login → delivery page | | | Not dashboard |
| C3-2 | | | | driver | Block staff routes | | | `/salesDashBoard` → redirect |
| C3-3 | | | | driver | Advance delivery order | | | status chain |
| C3-4 | | | | driver | Firestore field check | | | only status fields change |
| C3-5 | | | | staff | Staff sees driver update | | | Order list refresh |
| C4-1 | | | Android | staff | Manifest permissions | | | BLUETOOTH_* granted |
| C4-2 | | | Android | staff | Pair + print receipt | | | AppBar Bluetooth icon |

---

## Rules regression (Firebase Console Playground)

| Role | Operation | Expected | Date tested | PASS/FAIL | Notes |
|------|-----------|----------|-------------|-----------|-------|
| senior_florist | `counter/{id}_delivery` update | Allow | | | |
| senior_florist | `audit_logs` create | Allow | | | |
| driver | `audit_logs` create | **Deny** | | | |
| driver | `counters/{x}` read/update | **Deny** | | | |
| driver | `counter/{id}_delivery` read | Allow | | | |

---

## Counter initialization (per active company)

| Company doc ID | `_delivery` current | `_retail` current | Verified after test order | Date | Notes |
|----------------|---------------------|-------------------|---------------------------|------|-------|
| | | | | | |
| | | | | | |

Document IDs: `{companyDocId}_delivery` and `{companyDocId}_retail` in collection `counter`.  
If no company selected in app: `default_delivery` / `default_retail`.

---

## Peak rehearsal — Key paths (D1–D5)

| ID | Date | Executor | Platform | Path | Result | Order ID / evidence | Notes |
|----|------|----------|----------|------|--------|---------------------|-------|
| D1 | | | Android | Retail full flow (§3) | | | WI format, counter sync |
| D2 | | | | Delivery full flow (§4) | | | pending, address, PDF |
| D3 | | | staff + driver | Status chain | | | helpers mapping |
| D4 | | | Android | Bluetooth print (3 screens) | | | MAC, permissions |
| D5 | | | Web/Android | CSV export | | | tenant + date filter |

---

## Known issues / tickets

| Date | ID / link | Severity | Description | Status |
|------|-----------|----------|-------------|--------|
| | | | | |

---

*Fill rows as tests are executed. Attach screenshots or order IDs in Evidence column or linked folder.*
