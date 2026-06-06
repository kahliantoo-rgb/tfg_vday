# Peak operations runbook (one page)

Quick steps for **on-call / floor staff** during Valentine's peak.  
App: TFG VDAY · Firebase `tfg-sales-record` · See [WORKFLOW.md](WORKFLOW.md) for full flows.

---

## 1. Network outage / app “loading forever”

| Step | Who | Action |
|------|-----|--------|
| 1 | Anyone | Confirm Wi‑Fi/mobile data; try **airplane mode off**, reload app. |
| 2 | Staff | Switch device: **Android phone hotspot** or use **another phone/tablet** logged in as same role. |
| 3 | Staff | If Web only fails: use **Android app** (Bluetooth print needs device anyway). |
| 4 | Lead | Check [Firebase Status](https://status.firebase.google.com/) — if Google outage, **pause new orders**, take orders on paper. |
| 5 | Staff | Tap **Create Order** once per customer — if network fails, app **queues** the request (message shows *"Order queued (N pending)"*). Keep serving on paper. |
| 6 | Lead | When back: app **auto-syncs** queued orders on reconnect (Android/iOS). Verify in **Order List**; re-enter any paper-only orders manually. **Do not reuse** paper numbers — each app order gets a new ID. |
| 7 | Lead | Export **CSV** from Sales Report after recovery for reconciliation. |

**Do not:** delete Firestore orders from Console without tech lead.

---

## 2. Duplicate or “wrong” order number

| Symptom | Likely cause | Steps |
|---------|--------------|--------|
| Two orders show **same `TFG-…` / `TFG-WI…`** | Rare race or manual Console edit | 1. Note both order doc IDs in **Order List**.<br>2. **Do not** edit `counter/` in Console during peak.<br>3. Contact tech: run `npm run verify:peak` (counter docs must exist per company).<br>4. For customer-facing slip: use **Order List → open correct doc** → reprint; tell customer the ID on **that** screen. |
| Number **skipped** (e.g. 0005 then 0007) | Failed transaction mid-flow | **Safe to ignore** if both orders exist; sequence only moves forward. |
| **Retail** shows `TFG-YYYY-####` but should be `TFG-WI####` | Wrong branch (delivery vs retail) | Cancel/void per shop policy; create new order → tap **Retail** at product screen → pay again for WI number. |
| Counter reset to 0 after `init:counters` | Script re-run | Expected only **before** season; if run during peak, call tech immediately. |

**Prevention:** One staff member taps **Create Order** per customer; wait for product screen before second tap.

**Tech check (after peak):**

```bash
cd firebase
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccount.json
npm run verify:peak
```

Expect both `delivery` and `retail` counter docs to exist per company in report `counters.rows` (`ready: true`). Values may differ — channels use independent sequences.

---

## 3. Driver logged into wrong account / wrong screen

| Symptom | Steps |
|---------|--------|
| Driver sees **Sales Dashboard** | Wrong role on `users/{uid}` → **Log out** → tech runs `npm run set:user-role --email … --role driver` OR admin **Register** with role Driver. |
| Driver sees **empty** delivery list | 1. Confirm order status is `processing` / `ready_to_delivery` / `out_of_delivery` (chips on driver page).<br>2. Confirm order **same company** as driver `companyRef` (staff superadmin must pick company before creating test orders).<br>3. Staff: **Order List** → open order → advance status to `ready_to_delivery`. |
| Driver on **staff email** | Log out; use driver-only account (no dashboard menu). |
| Staff used **driver phone** to create orders | Log out driver → staff login → continue on dashboard. |

**Verify fix:** Driver login → lands on **My Deliveries** only (cannot open `/salesDashBoard` — blocked by app).

**Smoke account (internal):** see WORKFLOW §17 — use dedicated driver email, not admin.

---

## Escalation

| Issue | Contact | Command / doc |
|-------|---------|----------------|
| Rules / permission denied | Tech lead | `npm run deploy:rules:staging` then `deploy:rules:production` · [STAGING.md](STAGING.md) |
| Crashes / slow Create Order | Tech lead | Firebase **Crashlytics** + **Performance** · [OBSERVABILITY.md](OBSERVABILITY.md) |
| Counters / users | Tech lead | `npm run init:counters:dry-run` · `npm run fix:user-ids:dry-run` |
| Full test record | QA | [SMOKE_TEST_LOG.md](SMOKE_TEST_LOG.md) |

*Last updated: 2026-06-05*

**中文版：** [RUNBOOK_PEAK_OPERATIONS.zh.md](RUNBOOK_PEAK_OPERATIONS.zh.md) · PDF: [RUNBOOK_PEAK_OPERATIONS.zh.pdf](RUNBOOK_PEAK_OPERATIONS.zh.pdf)
