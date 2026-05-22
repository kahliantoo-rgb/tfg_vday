# TFG VDAY — System Workflows

Internal **POS + order + delivery** management for florist operations (Valentine's Day peak season).

| Item | Detail |
|------|--------|
| **Stack** | Flutter (FlutterFlow) · Firebase (Auth, Firestore, Storage) |
| **Backend** | Firebase project `tfg-sales-record` |
| **Platforms** | Web · Android · iOS (some features are mobile-only) |

---

## 1. System Entry & Roles

```mermaid
flowchart TD
    A[Open App] --> B{Logged in?}
    B -->|No| C[Login Page<br/>Firebase Auth]
    B -->|Yes| D[Sales Dashboard]
    C -->|Success| D
    D --> E{Multi-company?}
    E -->|Yes| F[Company Selection Page<br/>Save company to App State]
    E -->|No| G[Continue on Dashboard]
    F --> G

    G --> H{User Role}
    H -->|admin| I[Full access:<br/>orders, products, reports, audit, settings]
    H -->|senior_florist| J[Orders, products, status updates, printing]
    H -->|driver| K[Driver Delivery Page<br/>My Deliveries]
```

| Role | Main access |
|------|-------------|
| **admin** | Dashboard, orders, products, sales reports, audit logs, company settings |
| **senior_florist** | Dashboard, create/manage orders, product selection, status updates, printing |
| **driver** | Assigned deliveries only (`DriverDeliveryPage`) |

**User roles** (Firestore `users.role`): `admin` · `senior_florist` · `driver`

---

## 2. Create Order (Main Entry)

All new orders start from **Sales Dashboard → + Create Order**.

```mermaid
flowchart TD
    A[Sales Dashboard] --> B[+ Create Order]
    B --> C[Create Firestore order<br/>Order ID: TFG-YYYY-####]
    C --> D[Product Selection Page<br/>Add products → order_items]
    D --> E{Order type?}

    E -->|Retail| F[Set orderType = Retail<br/>status = completed]
    F --> G[Retail Summary<br/>Adjust qty, payment]
    G --> H[Receipt Preview<br/>Bluetooth thermal print]

    E -->|Delivery / Pick Up| I[Set orderType = Delivery<br/>status = pending]
    I --> J[DC Summary<br/>Payment: Cash / PayNow / Card]
    J --> K[Delivery Receipt Preview]
    K --> L[Create Order Form<br/>Customer & delivery details]
    L --> M[Delivery lifecycle + PDF / print]
```

| Step | Route / screen |
|------|----------------|
| Dashboard | `SalesDashBoard` → `/salesDashBoard` |
| Create order | Firestore `orders` + `ProductselectionCopy` |
| Retail branch | `RetailSummary` → `ReceiptPreviewpage2` |
| Delivery branch | `DCSummaryCopy` → `DeliveryReceiptPreviewPage` → `CreateOrderForm` |

---

## 3. Retail (In-Store POS) Workflow

```mermaid
sequenceDiagram
    participant Staff
    participant App
    participant Firestore
    participant Printer as Bluetooth Printer

    Staff->>App: Create Order
    App->>Firestore: orders (new doc)
    Staff->>App: Select products
    App->>Firestore: order_items
    Staff->>App: Tap Retail
    App->>Firestore: orderType=Retail, status=completed
    Staff->>App: Retail Summary → Confirm payment
    App->>Firestore: payment_method, paid_at, total
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
    F --> L[Assign driver]
    L --> M[Driver: My Deliveries]
    M --> N[Completed]
```

**Key Firestore fields (`orders`):**

| Field | Purpose |
|-------|---------|
| `client_name` | Customer name |
| `address`, `region`, `postal_code` | Delivery location |
| `delivery_date`, `delivery_time_slot` | Schedule |
| `card_message` | Greeting card text |
| `customer_phone_number` | Contact |
| `pickup_delivery` | Pick-up vs delivery |
| `assigned_driver` | Driver user reference |
| `orderType` | `Retail` or `Delivery` |
| `status` | Order lifecycle enum |

---

## 5. Order Status Lifecycle

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

| Status | Meaning | Typical actor |
|--------|---------|----------------|
| `pending` | New delivery order | System / cashier |
| `processing` | Florist preparing | senior_florist |
| `ready_to_delivery` | Ready to ship | senior_florist |
| `out_of_delivery` | On the road | driver |
| `completed` | Done | driver / staff |
| `cancelled` | Cancelled | admin / staff |

**Updated via:** `UpdateOrderStatus` sheet · `DriverDeliveryPage` · `OrderDetailPage`

---

## 6. Driver Delivery Workflow

```mermaid
flowchart TD
    A[Driver logs in] --> B[Driver Delivery Page]
    B --> C[Orders: assigned_driver = me]
    C --> D{Status?}
    D -->|ready_to_delivery| E[Start Delivery → out_of_delivery]
    D -->|out_of_delivery| F[Mark Delivered → completed]
    D -->|completed| G[Read-only]
```

**Screen:** `DriverDeliveryPage` → `/driverDeliveryPage`

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

```mermaid
sequenceDiagram
    participant Staff
    participant App
    participant System as OS Print Dialog

    Staff->>App: Print PDF (A4)
    App->>App: Load order + order_items + company
    App->>App: Build A4 PDF document
    App->>System: layoutPdf (printing package)
    Staff->>System: Choose printer or Save as PDF
```

---

## 8. Order Management & Reporting

```mermaid
flowchart TB
    subgraph Operations
        A[Sales Dashboard] --> B[All Orders]
        A --> C[Product List]
        B --> D[Order Detail]
        D --> E[Update Status]
        D --> F[Delivery Order Summary]
        F --> G[Print PDF / Preview]
    end

    subgraph Reporting
        H[Sales Report Page]
        I[CSV Export actions]
    end

    subgraph Admin
        J[Audit Log Page]
        K[Company Settings]
        L[Company Selection]
    end
```

---

## 9. End-to-End Overview (Peak Season)

```mermaid
flowchart TB
    subgraph Front["Front of house"]
        S1[Login] --> S2[Sales Dashboard]
        S2 --> S3{Walk-in or delivery?}
        S3 -->|Walk-in| S4[Retail → thermal receipt]
        S3 -->|Pre-order| S5[Delivery → PDF A4 + fulfillment]
    end

    subgraph Back["Back of house"]
        S5 --> B1[pending → processing → ready_to_delivery]
    end

    subgraph LastMile["Last mile"]
        B1 --> D1[Driver → out_of_delivery → completed]
    end

    subgraph Insight["Management"]
        S2 --> R1[Sales reports & CSV]
    end
```

---

## 10. Screen Map

| Purpose | Widget | Route |
|---------|--------|-------|
| Login | `LoginPage` | `/loginPage` |
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
| All orders | `Orderlist1` / `Orderlist` | — |
| Order details | `OrderDetailPage` | — |
| Driver view | `DriverDeliveryPage` | `/driverDeliveryPage` |
| Products | `Productlist` / `Productcreate` / `Customproductcreate` | — |
| Sales reports | `SalesReportPage` | — |
| Audit | `AuditLogPage` | — |
| Company settings | `CompanySettingPage` | — |

---

## 11. Firestore Collections

| Collection | Purpose |
|------------|---------|
| `orders` | Order header: customer, delivery, status, totals, payment |
| `order_items` | Line items: product, qty, price, subtotal |
| `product` | Catalog: name, price, SKU, image, category |
| `users` | Staff: role, display name, company link |
| `companies` | Company name, UEN, phone, address |
| `audit_logs` | Admin activity trail |
| `counters` | Order ID counters |

---

## 12. Custom Code Modules

| File | Purpose |
|------|---------|
| `lib/custom_code/bluetooth_receipt_printer.dart` | Pair Bluetooth printer, print ESC/POS receipts |
| `lib/custom_code/delivery_order_pdf_printer.dart` | Generate & print/share A4 delivery PDF |
| `lib/custom_code/actions/print_order_receipt_esc_pos.dart` | FlutterFlow action: thermal print |
| `lib/custom_code/actions/export_orders_to_csv.dart` | Export orders CSV |
| `lib/custom_code/actions/export_order_items_final_csv.dart` | Export line items CSV |
| `lib/custom_code/actions/export_orders_items_pickup_csv.dart` | Pick-up / delivery CSV |

---

## 13. Custom Actions (FlutterFlow)

| Action | Purpose |
|--------|---------|
| `printOrderReceiptEscPos` | Bluetooth thermal receipt (legacy / action) |
| `exportOrdersToCsv` | Export orders |
| `exportOrderItemsFinalCsv` | Export order line items |
| `exportOrdersItemsPickupCsv` | Pick-up / delivery export |

---

## 14. Platform Notes

| Feature | Web | Android | iOS |
|---------|-----|---------|-----|
| Login / Firestore | Yes | Yes | Yes |
| Create & manage orders | Yes | Yes | Yes |
| Bluetooth thermal print | No | Yes | Yes |
| PDF A4 print / share | Yes | Yes | Yes |
| CSV export | Yes | Yes | Yes |

**Android:** Bluetooth permissions in `AndroidManifest.xml` (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, location for discovery).

---

*Repository: [kahliantoo-rgb/tfg_vday](https://github.com/kahliantoo-rgb/tfg_vday) · Mermaid diagrams render in GitHub, VS Code, and Cursor.*
