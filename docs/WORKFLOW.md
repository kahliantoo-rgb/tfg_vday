# TFG VDAY — System Workflows

Internal **POS + order + delivery** management for florist operations (Valentine's Day peak season).

| Item | Detail |
|------|--------|
| **Stack** | Flutter (FlutterFlow) · Firebase (Auth, Firestore, Storage) |
| **Backend** | Firebase project `tfg-sales-record` |
| **Platforms** | Web · Android · iOS (some features are mobile-only) |

---

## 1. System Entry, Auth & Roles

All business routes require Firebase Auth (`requireAuth = true`). Only `/loginPage` is public.

```mermaid
flowchart TD
    A[Open App /] --> B{Logged in?}
    B -->|No| C[Login Page<br/>Firebase Auth]
    B -->|Yes| D[PostLoginRouter<br/>load role]
    C -->|Success| D
    D --> E{User role?}
    E -->|driver| F[Driver Delivery Page]
    E -->|superadmin / admin / senior_florist| G[Sales Dashboard]
    G --> H{superadmin?}
    H -->|Yes| I[View all companies]
    H -->|No| J[Company scope from profile]
    I --> K[Continue on Dashboard]
    J --> K
```

### Role-based routing

| Role | Cross-company view | After login | Typical scope |
|------|-------------------|-------------|---------------|
| **superadmin** | Yes — all companies | Sales Dashboard | Platform owner; create/delete `Companies`; all admin UI |
| **admin** | No — own `companyRef` | Sales Dashboard | Company admin; register staff; company settings |
| **senior_florist** | No — own `companyRef` | Sales Dashboard | Orders, products, status, print, CSV |
| **driver** | No | Driver Delivery Page | **Only** `/`, `/loginPage`, `/driverDeliveryPage` |

**Implementation:** `lib/auth/role_helpers.dart` · `lib/auth/auth_redirect.dart` · `lib/auth/role_route_guard.dart` · `TenantContext.canViewAllCompanies()` (superadmin only).

### User profile (Firestore)

Each Firebase Auth user must have a document:

```
users/{auth.uid}
  role: superadmin | admin | senior_florist | driver
  email: ...
  name: ...
  uid: {auth.uid}   (required — doc id must match Auth UID)
  companyRef: ...    (required for admin / senior_florist / driver; optional for superadmin)
  is_active: true    (default; false blocks login)
  created_time, phone_number, display_name
```

Profile is resolved by **uid first**, then **email** (`lib/backend/user_query_helpers.dart`).

---

## 2. Create Order (Main Entry)

All new orders start from **Sales Dashboard → + Create Order** (staff only).

```mermaid
flowchart TD
    A[Sales Dashboard] --> B[+ Create Order]
    B --> C[OrderIdService.nextDeliveryOrderId<br/>Firestore counter/delivery transaction]
    C --> D[Create Firestore orders doc<br/>Order ID: TFG-YYYY-####]
    D --> E[Product Selection Page<br/>Add products → Order_item]
    E --> F{Order type?}

    F -->|Retail| G[Set orderType = Retail<br/>status = completed]
    G --> H[Retail Summary<br/>Adjust qty, payment]
    H --> I[Confirm Payment → OrderIdService.nextRetailOrderId<br/>TFG-WI####]
    I --> J[Receipt Preview<br/>Bluetooth thermal print]

    F -->|Delivery / Pick Up| K[Set orderType = Delivery<br/>status = pending]
    K --> L[DC Summary<br/>Payment: Cash / PayNow / Card]
    L --> M[Delivery Receipt Preview]
    M --> N[Create Order Form<br/>Customer & delivery details]
    N --> O[Delivery lifecycle + PDF / print]
```

| Step | Route / screen |
|------|----------------|
| Dashboard | `SalesDashBoard` → `/salesDashBoard` |
| Create order | Firestore `orders` + `ProductselectionCopy` |
| Retail branch | `RetailSummary` → `ReceiptPreviewpage2` |
| Delivery branch | `DCSummaryCopy` → `DeliveryReceiptPreviewPage` → `CreateOrderForm` |

### Custom products (one-off line items)

Staff can add a **Customize** SKU from:

- **Product Selection** — bottom “Have a Customize product?” fields + **Create**
- **Custom product Form** — `/customproductcreate` (full name / qty / price / remark)

On **Create**, a dialog asks:

| Option | Action |
|--------|--------|
| **Upload Photo** | Pick image → Firebase Storage `custom_product_images/{orderItemId}/…` → save `Order_item` with optional `image` URL |
| **Add** | Save line item without photo |
| **Cancel** | No write |

**Implementation:** `lib/backend/custom_product_helpers.dart` · `Order_item.sku = 'Customize'`

### Order ID format

| Type | Format | Counter doc |
|------|--------|-------------|
| Delivery / pre-order | `TFG-2026-0001` | `counter/{companyId}_delivery` |
| Retail walk-in | `TFG-WI0001` | `counter/{companyId}_retail` |

Delivery and retail **share the same sequence number** (both counter docs update together). Initialize before peak season (optional):

```
counter/{companyId}_delivery  →  { current: 0 }
counter/{companyId}_retail    →  { current: 0 }   // same value as delivery
```

Generated via atomic Firestore transaction (`lib/backend/order_id_service.dart`).

---

## 3. Retail (In-Store POS) Workflow

```mermaid
sequenceDiagram
    participant Staff
    participant App
    participant Firestore
    participant Printer as Bluetooth Printer

    Staff->>App: Create Order
    App->>Firestore: orders (TFG-YYYY-####)
    Staff->>App: Select products
    App->>Firestore: Order_item
    Staff->>App: Tap Retail
    App->>Firestore: orderType=Retail, status+orderstatus=completed
    Staff->>App: Retail Summary → Confirm payment
    App->>Firestore: totalAmount, orderId=TFG-WI####
    Staff->>App: Receipt Preview → Print Receipt
    App->>Printer: ESC/POS via Bluetooth
```

**Steps:** Dashboard → Create Order → Product Selection → **Retail** → Retail Summary → Pay → **Receipt Preview** → Print (thermal).

| Screen | Print action |
|--------|----------------|
| `ReceiptPreviewpage2` | App bar: select Bluetooth printer · **Print Receipt** |

---

## 4. Delivery / Pick-Up Workflow

```mermaid
flowchart TD
    A[Product Selection] --> B[Delivery / Pick Up]
    B --> C[DC Summary + Payment]
    C --> D[Delivery Receipt Preview]
    D --> E[Create Order Form]
    E --> F[Order List / Order Detail]
    F --> G[Delivery Order Summary]
    G --> H{Print options}
    H -->|A4 PDF| I[System print / Save PDF]
    H -->|Thermal| J[Bluetooth receipt]
    H -->|Preview| K[Delivery Order Print screen]
    F --> L[Assign driver<br/>assigned_driver ref]
    L --> M[Driver: My Deliveries]
    M --> N[Completed]
```

**Key Firestore fields (`orders`):**

| Field | Purpose |
|-------|---------|
| `Order_Id` | Display order number (`orderId` in app) |
| `client_name` | Customer name |
| `address`, `region`, `PostalCode` | Delivery location |
| `delivery_date`, `delivery_time_slot` | Schedule |
| `card_message` | Greeting card text |
| `customer_phone_number` | Contact |
| `pickup_delivery` | Pick-up vs delivery |
| `assigned_driver` | Reference to `users/{uid}` |
| `orderType` | `Retail` or `Delivery` |
| `status` | Order lifecycle enum (canonical) |
| `orderstatus` | Legacy string mirror for list filters (kept in sync on write) |

**Assigned driver display:** `DeliveryOrderSummaryPage` loads driver name via `orders.assigned_driver` → `users` document (not a random user query).

---

## 5. Order Status Lifecycle

Both `status` (enum) and `orderstatus` (legacy string) are updated together via `createOrderStatusUpdateData()` in `lib/backend/order_status_helpers.dart`.

```mermaid
stateDiagram-v2
    [*] --> pending: Delivery order created
    pending --> processing: Florist starts work
    processing --> ready_to_delivery: Arrangement ready
    ready_to_delivery --> out_of_delivery: Driver starts
    out_of_delivery --> completed: Delivered
    pending --> cancelled
    processing --> cancelled
    ready_to_delivery --> cancelled
    out_of_delivery --> cancelled
    completed --> [*]
    cancelled --> [*]
```

| `status` (enum) | `orderstatus` (legacy filter) | Meaning | Typical actor |
|-----------------|-------------------------------|---------|----------------|
| `pending` | `pending` | New delivery order | staff |
| `processing` | `processing` | Florist preparing | senior_florist |
| `ready_to_delivery` | `readyToShip` | Ready to ship | senior_florist |
| `out_of_delivery` | `outOfDelivery` | On the road | driver |
| `completed` | `completed` | Done | driver / staff |
| `cancelled` | `cancelled` | Cancelled | admin / staff |

**Updated via:** `UpdateOrderStatus` sheet · `DriverDeliveryPage` · bulk actions on **Order List** · `OrderDetailPage`

**Driver Firestore constraint:** drivers may only update `status`, `orderstatus`, and `delivery_time_actual` on orders (see §15).

---

## 6. Driver Delivery Workflow

```mermaid
flowchart TD
    A[Driver logs in] --> B[PostLoginRouter]
    B --> C[Driver Delivery Page]
    C --> D[Filter orders by status chip]
    D --> E{Status?}
    E -->|processing| F[Advance → ready_to_delivery]
    E -->|ready_to_delivery| G[Advance → out_of_delivery]
    E -->|out_of_delivery| H[Advance → completed]
    F --> I[Sync status + orderstatus]
    G --> I
    H --> I
```

**Screen:** `DriverDeliveryPage` → `/driverDeliveryPage`

Drivers **cannot** open Sales Dashboard, create orders, or edit order line items (enforced by app routing + Firestore rules).

---

## 7. Printing Workflows

Two print paths: **Bluetooth thermal** (receipt) and **PDF A4** (delivery order document).

```mermaid
flowchart LR
    subgraph Retail["Retail / POS"]
        R1[ReceiptPreviewpage2] --> R2[Bluetooth icon: pair printer]
        R1 --> R3[Print Receipt: thermal]
    end

    subgraph Delivery["Delivery order"]
        D1[Delivery Receipt Preview] --> D2[PDF A4]
        D1 --> D3[Thermal]
        D4[Delivery Order Summary] --> D5[Print PDF A4]
        D4 --> D6[Preview]
        D7[DeliveryOrderPrint / dO] --> D8[PDF print / share]
    end
```

### 7.1 Bluetooth thermal (ESC/POS)

| Item | Detail |
|------|--------|
| **Module** | `lib/custom_code/bluetooth_receipt_printer.dart` |
| **Package** | `flutter_bluetooth_printer` |
| **Platform** | Android & iOS only (not Web) |
| **Saved printer** | MAC address in App State (`ff_bluetooth_printer_address`) |
| **Company header** | `getDefaultCompanyOnce()` — first company by name |

**First-time setup**

1. Open receipt preview (Retail or Delivery).
2. Tap **Bluetooth** icon in app bar → select printer from list.
3. Tap **Print Receipt** / **Thermal**.

**Receipt content:** company name, order ID, date, items, total, delivery info (if applicable), thank-you line.

### 7.2 PDF A4 (delivery order)

| Item | Detail |
|------|--------|
| **Module** | `lib/custom_code/delivery_order_pdf_printer.dart` |
| **Packages** | `pdf` · `printing` |
| **Platform** | Web, Android, iOS, desktop (system print dialog) |

**Where to print**

| Screen | Button / action |
|--------|-----------------|
| `DeliveryOrderSummaryPage` | **Print PDF (A4)** · **Preview** |
| `DeliveryReceiptPreviewPage` | **PDF A4** |
| `DeliveryOrderPrint` | App bar PDF icon (print) · Share icon (export PDF) |
| `DOWidget` (`/dO`) | App bar PDF icon |

**PDF content:** company header · order number & date · customer & delivery details · items table · subtotal/total · driver name · signature lines.

---

## 8. Order Management & Reporting

```mermaid
flowchart TB
    subgraph Operations
        A[Sales Dashboard] --> B[Order List /orderlist]
        A --> C[Product List]
        B --> D[Order Detail]
        D --> E[Update Status]
        D --> F[Delivery Order Summary]
        F --> G[Print PDF / Preview]
    end

    subgraph Reporting
        A --> V[View Reports]
        V --> H[Daily Sales Report<br/>date · totals · PayNow/Cash/Card]
        I[CSV Export actions]
    end

    subgraph Admin
        J[Audit Log Page]
        K[Company Settings]
        L[Company Selection]
    end
```

### Order List (unified)

| Item | Detail |
|------|--------|
| **Canonical route** | `/orderlist` (`Orderlist1Widget`) |
| **Legacy alias** | `/orderlist1` → redirects to `/orderlist` |
| **Widget alias** | `OrderlistWidget` extends `Orderlist1Widget` |
| **Filters** | Date range · `orderstatus` dropdown · order type chips · bulk status update |

Entry points: Sales Dashboard · Home Page · app bar search icon.

**Order list type chips:** All · Retail · Delivery · Pick Up (`lib/backend/order_list_filter_helpers.dart`).

### Daily sales report

Staff open **Sales Dashboard → View Reports** (`/salesReportPage`).

```mermaid
flowchart LR
    DB[Sales Dashboard] --> VR[View Reports]
    VR --> DP[Pick report date]
    DP --> Q[Query tenant orders<br/>created_time in day]
    Q --> F[Filter: paymentType set,<br/>not cancelled, amount > 0]
    F --> A[Aggregate]
    A --> T[Total orders · Total sales]
    A --> P[PayNow / Cash / Card totals<br/>per method + order count]
```

| Output | Source |
|--------|--------|
| Report date | User-selected calendar day (default: today) |
| Total orders | Count of qualifying paid orders |
| Total sales | Sum of `totalAmount` (fallback `total`) |
| **PayNow total** | Sum where `paymentType` normalizes to PayNow |
| Cash / Card totals | Same pattern |

**Implementation:** `lib/backend/daily_sales_report_service.dart` · `lib/pages/sales_report_page/sales_report_page_widget.dart`

**Note:** Report uses **`created_time`** and **`paymentType`** (set on Retail Summary or DC Summary payment step). Orders without a payment method are excluded.

### Staff registration & user management

- Public self-registration on login is **disabled**; **admin / superadmin** create staff after login (`RegisterPage` `/register`).
- **superadmin** can pick company when creating staff; **admin** is company-scoped.
- **User List** (`/userListPage`) — admin / superadmin only:
  - Columns: **Name**, **Role**, **Status** (Active / Inactive)
  - Multi-select → **Set Inactive**, **Activate**, or **Delete** (Firestore profile only)
  - **Admin** may manage drivers and senior florists in their company (not other admins / superadmins)
  - **Superadmin** may manage all staff except their own account
  - Inactive users cannot log in (`is_active: false`)
- Entry points: **Sales Dashboard → User List** · **Company Profile → View User List** · **Add Staff**
- **Home** button on staff screens returns to Sales Dashboard (`lib/components/home_nav_button.dart`).
- **Driver** app bar and footer include **Logout**.

**Implementation:** `lib/pages/user_list_page/` · `lib/backend/user_list_helpers.dart` · `lib/backend/user_admin_service.dart` · `lib/auth/role_helpers.dart` (`canViewUserList`)

---

## 9. End-to-End Overview (Peak Season)

```mermaid
flowchart TB
    subgraph Front["Front of house (staff)"]
        S1[Login] --> S2[Sales Dashboard]
        S2 --> S3{Walk-in or delivery?}
        S3 -->|Walk-in| S4[Retail → TFG-WI#### → thermal receipt]
        S3 -->|Pre-order| S5[Delivery → TFG-YYYY-#### → PDF A4 + fulfillment]
    end

    subgraph Back["Back of house"]
        S5 --> B1[pending → processing → ready_to_delivery]
    end

    subgraph LastMile["Last mile (driver)"]
        B1 --> D1[Driver app → out_of_delivery → completed]
    end

    subgraph Insight["Management"]
        S2 --> R1[View Reports → daily totals & PayNow/Cash/Card]
        S2 --> R2[CSV export]
    end
```

---

## 10. Screen Map

| Purpose | Widget | Route |
|---------|--------|-------|
| Login | `LoginPage` | `/loginPage` |
| Role router | `PostLoginRouterWidget` | `/` |
| Home hub | `HomePage` | `/homePage` |
| Sales hub | `SalesDashBoard` | `/salesDashBoard` |
| Company pick | `CompanySelectionPage` | `/companySelectionPage` |
| Product pick | `ProductselectionCopy` | `/productselectionCopy` |
| Retail checkout | `RetailSummary` | `/retailSummary` |
| Retail receipt + thermal | `ReceiptPreviewpage2` | `/receiptPreviewpage2` |
| Delivery checkout | `DCSummaryCopy` | `/deliverySummaryCopy` |
| Delivery receipt | `DeliveryReceiptPreviewPage` | `/deliveryreceiptPreviewPage` |
| Customer form | `CreateOrderForm` | `/createOrderForm` |
| Delivery summary + PDF | `DeliveryOrderSummaryPage` | `/deliveryOrderSummaryPage` |
| Delivery A4 preview | `DeliveryOrderPrint` | `/deliveryOrderPrint` |
| Delivery A4 alt | `DOWidget` | `/dO` |
| **All orders** | `Orderlist1Widget` / `OrderlistWidget` | **`/orderlist`** |
| Order details | `OrderDetailPage` | `/orderDetailPage` |
| Driver view | `DriverDeliveryPage` | `/driverDeliveryPage` |
| Products | `Productlist` / `Productcreate` / `Customproductcreate` | various |
| Sales reports | `SalesReportPage` | `/salesReportPage` |
| Audit | `AuditLogPage` | `/auditLogPage` |
| Company settings | `CompanySettingPage` | `/companySettingPage` |
| Register staff | `RegisterPage` | `/register` |
| **User list** | `UserListPage` | `/userListPage` |

---

## 11. Firestore Collections

| Collection | Purpose |
|------------|---------|
| `orders` | Order header: customer, delivery, status, totals, payment, `Order_Id` |
| `Order_item` | Line items: product, qty, price, subtotal, `orderRef`, optional `image` (custom products) |
| `product` | Catalog: name, price, SKU, image, category |
| `users` | Staff profiles: **doc ID = auth.uid**, `role`, name, email, `is_active` |
| `Companies` | Company name, UEN, phone, address (used on receipts/PDF) |
| `deleted_orders` | Archived orders removed from active list (admin audit trail) |
| `audit_logs` | Admin activity trail (staff read) |
| `counter` | Sequential order IDs: `delivery`, `retail` |
| `counters` | Legacy counter collection (deprecated; staff read/write only) |

### Loading orders correctly

Always load a single order by document reference — **never** `queryOrdersRecord(singleRecord: true)` without a filter:

```dart
OrdersRecord.getDocument(orderRef)
// or
OrderRecordBuilder(orderRef: orderRef, builder: ...)
```

See `lib/backend/order_query_helpers.dart`.

---

## 12. Backend Helper Modules

| File | Purpose |
|------|---------|
| `lib/backend/order_query_helpers.dart` | `OrderRecordBuilder`, stream by `orderRef` |
| `lib/backend/order_status_helpers.dart` | Sync `status` + `orderstatus` on writes |
| `lib/backend/order_id_service.dart` | Transaction-based `TFG-*` / `TFG-WI*` IDs |
| `lib/backend/company_query_helpers.dart` | Default company for receipts/PDF (by name) |
| `lib/backend/user_query_helpers.dart` | Resolve current user profile (uid → email) |
| `lib/backend/user_list_helpers.dart` | User list display, tenant filter, manage permissions |
| `lib/backend/user_admin_service.dart` | Set `is_active`, delete user profiles (batch) |
| `lib/backend/order_delete_service.dart` | Archive orders to `deleted_orders` then delete |
| `lib/backend/custom_product_helpers.dart` | Customize product dialog, photo upload, line-item create |
| `lib/auth/auth_redirect.dart` | Post-login route by role |
| `lib/auth/role_route_guard.dart` | Driver route allow-list |

---

## 13. Custom Code Modules

| File | Purpose |
|------|---------|
| `lib/custom_code/bluetooth_receipt_printer.dart` | Pair Bluetooth printer, print ESC/POS receipts |
| `lib/custom_code/delivery_order_pdf_printer.dart` | Generate & print/share A4 delivery PDF |
| `lib/custom_code/actions/print_order_receipt_esc_pos.dart` | FlutterFlow action: thermal print |
| `lib/custom_code/actions/export_orders_to_csv.dart` | Export orders CSV |
| `lib/custom_code/actions/export_order_items_final_csv.dart` | Export line items CSV |
| `lib/custom_code/actions/export_orders_items_pickup_csv.dart` | Pick-up / delivery CSV |

---

## 14. Custom Actions (FlutterFlow)

| Action | Purpose |
|--------|---------|
| `printOrderReceiptEscPos` | Bluetooth thermal receipt |
| `exportOrdersToCsv` | Export orders |
| `exportOrderItemsFinalCsv` | Export order line items |
| `exportOrdersItemsPickupCsv` | Pick-up / delivery export |

---

## 15. Firestore Security Rules

Rules file: `firebase/firestore.rules` — deploy with:

```bash
firebase deploy --only firestore:rules
```

### Permission matrix

| Collection | Read | Create | Update | Delete |
|------------|------|--------|--------|--------|
| `orders` | staff + driver; **tenant-scoped**¹ | staff; tenant on write | staff; tenant on write; driver: status fields only | platform admin |
| `Order_item` | staff + driver; **tenant-scoped**¹ | staff; tenant on write | staff; tenant on write | platform admin |
| `product` / `customProduct` | signed-in; **tenant-scoped**¹ | staff; tenant on write | staff; tenant on write | platform admin |
| `users` | self + staff | self (uid match) | self + platform admin | platform admin |
| `Companies` | signed-in | **superadmin** | platform admin | **superadmin** |
| `counters` | staff | staff | staff | platform admin |
| `counter` | staff + driver; **counter ID scoped**² | staff; counter ID scoped | staff; counter ID scoped | platform admin |
| `audit_logs` | staff; **tenant-scoped**¹ | staff; tenant on write | — | — |
| `deleted_orders` | platform admin; **tenant-scoped**¹ | platform admin; tenant on write | — | — |

**Role helpers:** `isSuperAdminUser()` · `isPlatformAdminUser()` · `isStaffUser()` · `isDriverUser()` · `canCrossTenantAccess()` (superadmin only) · `canViewUserList()` (admin + superadmin).

**Tenant helpers:**

1. **`docBelongsToAuthTenant` / `incomingBelongsToAuthTenant`** — only **`superadmin`** bypasses company scope. Other staff/drivers need matching `companyRef`. Legacy docs without `companyRef` remain accessible.
2. **`counterDocBelongsToAuthTenant`** — counter doc IDs must match `{companyId}_*` for the user’s company (or `default_*`).

**Rules regression tests:** `firebase/test/firestore.rules.test.js` — run `npm run test:rules` from `firebase/`.

### Driver update constraint

Drivers may only change these fields on an existing order:

- `status`
- `orderstatus`
- `delivery_time_actual`

---

## 16. Deployment Checklist (Peak Season)

**On-call runbook (one page):** [RUNBOOK_PEAK_OPERATIONS.md](RUNBOOK_PEAK_OPERATIONS.md) — network outage, duplicate order numbers, driver wrong account.

1. **Deploy Firestore rules:** `firebase deploy --only firestore:rules --project tfg-sales-record`
2. **Deploy Web app** (after `flutter build web --release` from repo root):

   ```bash
   # Copy build/web → firebase/public (see README)
   cd firebase
   firebase deploy --only hosting --project tfg-sales-record
   ```

   Production URL: **https://tfg-sales-record.web.app** — hard-refresh after deploy (Ctrl+Shift+R).

   Combined rules + hosting: `firebase deploy --only hosting,firestore:rules --project tfg-sales-record`

3. **Automated checks** (from `firebase/`):
   - `npm run verify:peak` — users/roles, counter pairs, rules tests (needs service account + Java for full run)
   - `npm run test:firebase` — rules + counter init against emulator (CI)
4. **Initialize counters** (production, before peak):

   ```bash
   cd firebase
   # Service account from Firebase Console → Project Settings → Service accounts
   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccount.json
   npm run init:counters:dry-run   # preview
   npm run init:counters           # write counter/{companyId}_delivery + _retail
   ```

   Creates/syncs `{companyId}_delivery` and `{companyId}_retail` for every active `Companies` doc, plus `default_*`.

5. **User documents:** ensure every Auth user has `users/{uid}` with correct `role` (drivers need `companyRef`)

   **Driver smoke account (optional script):**

   ```bash
   cd firebase
   node scripts/create_driver_user.js \
     --email driver@example.com --password "YourPass123!" \
     --name "Driver Name" --company-id lc3Dhfby8f35Md0E1vZC \
     --key C:\path\to\serviceAccount.json
   ```

   Or in app: admin login → **Register** (`/register`) → role **Driver** → select company.

   **Superadmin (cross-company):**

   ```bash
   node scripts/set_user_role.js --email YOUR_EMAIL --role superadmin --key C:\path\to\serviceAccount.json
   ```

6. **Smoke test staff:** create delivery order for driver — see §17
7. **Smoke test driver:** login → delivery page → advance status — see §17
8. **Android:** Bluetooth permissions already in manifest for thermal printing

---

## 17. Staff → Driver delivery smoke test

Use **admin** or **senior_florist** (same company as driver) + driver account `tfg.driver.smoke@gmail.com`.

### A. Staff — create delivery order (~10 min)

1. Login as staff (`kahliantoo@gmail.com` or `yanyitoo1025@gmail.com`).
2. **Superadmin only:** app bar / company chip → **All companies** or pick one company before creating orders.
3. **Sales Dashboard** → **+ Create Order**.
4. **Product Selection** → add at least one product.
5. Tap **Delivery / Pick Up** (not Retail).
6. **DC Summary** → choose payment (Cash / PayNow / Card) → continue.
7. **Delivery Receipt Preview** → continue.
8. **Create Order Form** → fill:
   - Client name, phone
   - Address, postal code, region
   - Delivery date & time slot
   - Card message (optional)
9. Submit → note order ID (`TFG-YYYY-####`).
10. **Order List** → open the order → **Update Status** → set `processing` or `ready_to_delivery` (driver filters by status chips).

> Driver page lists orders by **status** for the same company (not filtered by `assigned_driver` in current build).

### B. Driver — advance status (~5 min)

1. Log out → login as `tfg.driver.smoke@gmail.com` / `TfgDriver2026!`
2. Confirm landing on **My Deliveries** (not Sales Dashboard).
3. Use status chips → find the test order.
4. Advance: `processing` → `ready_to_delivery` → `out_of_delivery` → `completed`.

### C. Staff — verify (~2 min)

1. Log back in as staff → **Order List** → confirm final status `completed`.

### Test accounts (2026-06-03)

| Role | Email | Notes |
|------|-------|-------|
| superadmin | `kahliantoo@gmail.com` | Cross-company after role upgrade |
| senior_florist | `yanyitoo1025@gmail.com` | Company-scoped |
| driver | `tfg.driver.smoke@gmail.com` | Password `TfgDriver2026!` |

---

## 18. Platform Notes

| Feature | Web | Android | iOS |
|---------|-----|---------|-----|
| Login / Firestore | Yes | Yes | Yes |
| Create & manage orders (staff) | Yes | Yes | Yes |
| Driver delivery page | Yes | Yes | Yes |
| Bluetooth thermal print | No | Yes | Yes |
| PDF A4 print / share | Yes | Yes | Yes |
| CSV export | Yes | Yes | Yes |

**Android:** Bluetooth permissions in `AndroidManifest.xml` (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, location for discovery).

**Flutter 3.44:** if `page_transition` build fails, add `import 'package:flutter/cupertino.dart';` to the package's `page_transition.dart` in pub cache.

---

*Repository: [kahliantoo-rgb/tfg_vday](https://github.com/kahliantoo-rgb/tfg_vday) · Mermaid diagrams render in GitHub, VS Code, and Cursor.*
