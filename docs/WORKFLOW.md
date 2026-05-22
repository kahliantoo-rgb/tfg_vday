# TFG VDAY — System Workflows

Internal POS + order + delivery management for florist operations (Valentine's Day peak season).

**Stack:** Flutter (FlutterFlow) · Firebase (Auth, Firestore, Storage)

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
| **senior_florist** | Dashboard, create/manage orders, product selection, status updates |
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
    G --> H[Receipt Preview / Print<br/>Bluetooth ESC/POS]

    E -->|Delivery / Pick Up| I[Set orderType = Delivery<br/>status = pending]
    I --> J[DC Summary<br/>Payment: Cash / PayNow / Card]
    J --> K[Delivery Receipt Preview]
    K --> L[Create Order Form<br/>Name, address, region,<br/>delivery date/time, card message]
    L --> M[Order enters delivery lifecycle]
```

| Step | Route / screen |
|------|----------------|
| Dashboard | `SalesDashBoard` |
| Create order | Firestore `orders` doc + `ProductselectionCopy` |
| Retail branch | `RetailSummary` → `ReceiptPreviewpage2` |
| Delivery branch | `DCSummaryCopy` → `DeliveryReceiptPreviewPage` → `CreateOrderForm` |

---

## 3. Retail (In-Store POS) Workflow

```mermaid
sequenceDiagram
    participant Staff
    participant App
    participant Firestore

    Staff->>App: Create Order
    App->>Firestore: orders (new doc)
    Staff->>App: Select products
    App->>Firestore: order_items (qty, subtotal)
    Staff->>App: Tap Retail
    App->>Firestore: orderType=Retail, status=completed
    Staff->>App: Retail Summary
    Staff->>App: Confirm payment
    App->>Firestore: payment_method, paid_at, total
    Staff->>App: Print receipt
    App->>Staff: Bluetooth thermal print (ESC/POS)
```

**Steps:** Dashboard → Create Order → Product Selection → **Retail** → Retail Summary → Pay → Receipt / Print.

---

## 4. Delivery / Pick-Up Workflow

```mermaid
flowchart LR
    A[Product Selection] --> B[Delivery / Pick Up]
    B --> C[DC Summary + Payment]
    C --> D[Delivery Receipt Preview]
    D --> E[Create Order Form<br/>Customer & delivery info]
    E --> F[Order List / Order Detail<br/>Florist fulfillment]
    F --> G[Assign driver optional]
    G --> H[Driver: My Deliveries]
    H --> I[Delivered]
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
| `assigned_driver` | Driver reference |
| `orderType` | `Retail` or `Delivery` |

---

## 5. Order Status Lifecycle (Florist / Staff)

```mermaid
stateDiagram-v2
    [*] --> pending: Delivery order created
    pending --> processing: Florist starts work
    processing --> ready_to_delivery: Arrangement ready
    ready_to_delivery --> out_of_delivery: Driver starts / staff marks
    out_of_delivery --> completed: Delivered
    pending --> cancelled: Cancel order
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

**Where status is updated:**

- `UpdateOrderStatus` sheet (from Order List / Order Detail)
- `DriverDeliveryPage` (driver actions)
- `OrderDetailPage` (e.g. Start Delivery)

---

## 6. Driver Delivery Workflow

```mermaid
flowchart TD
    A[Driver logs in] --> B[Driver Delivery Page<br/>My Deliveries]
    B --> C[Filter: Assigned / Out for Delivery / Completed]
    C --> D[Orders where assigned_driver = current user]
    D --> E{Current status?}
    E -->|ready_to_delivery| F[Start Delivery]
    F --> G[status → out_of_delivery]
    E -->|out_of_delivery| H[Mark as Delivered]
    H --> I[status → completed]
    E -->|completed| J[Read-only / disabled]
```

**Screen:** `DriverDeliveryPage` (`/driverDeliveryPage`)

---

## 7. Order Management & Reporting

```mermaid
flowchart TB
    subgraph Operations
        A[Sales Dashboard] --> B[All Orders]
        A --> C[Product List]
        C --> D[Create / Edit Product]
        C --> E[Custom Product Create]
        B --> F[Order Detail]
        F --> G[Update Status]
        F --> H[Delivery Order Summary]
        F --> I[Print Delivery Order]
    end

    subgraph Reporting
        J[Sales Report Page<br/>Today / month, by orderType]
        K[Export CSV<br/>orders, items, pickup/delivery]
    end

    subgraph Admin
        L[Audit Log Page]
        M[Company Settings]
        N[Company Selection]
    end
```

---

## 8. End-to-End Overview (Peak Season)

```mermaid
flowchart TB
    subgraph Front["Front of house"]
        S1[Staff login] --> S2[Sales Dashboard]
        S2 --> S3{Walk-in or delivery?}
        S3 -->|Walk-in| S4[Retail POS flow]
        S3 -->|Phone / pre-order| S5[Delivery flow]
    end

    subgraph Back["Back of house"]
        S5 --> B1[pending]
        B1 --> B2[processing]
        B2 --> B3[ready_to_delivery]
    end

    subgraph LastMile["Last mile"]
        B3 --> D1[Driver assigned]
        D1 --> D2[out_of_delivery]
        D2 --> D3[completed]
    end

    subgraph Insight["Management"]
        S2 --> R1[Sales reports & CSV export]
        R1 --> R2[Audit logs]
    end
```

---

## 9. Screen Map

| Purpose | Widget / route |
|---------|----------------|
| Login | `LoginPage` → `/loginPage` |
| Sales hub | `SalesDashBoard` → `/salesDashBoard` |
| Company pick | `CompanySelectionPage` → `/companySelectionPage` |
| Product pick | `ProductselectionCopy` → `/productselectionCopy` |
| Retail checkout | `RetailSummary` → `/retailSummary` |
| Retail receipt | `ReceiptPreviewpage2` |
| Delivery checkout | `DCSummaryCopy` → `/deliverySummaryCopy` |
| Delivery receipt | `DeliveryReceiptPreviewPage` |
| Customer form | `CreateOrderForm` → `/createOrderForm` |
| All orders | `Orderlist1` / `Orderlist` |
| Order details | `OrderDetailPage` |
| Driver view | `DriverDeliveryPage` → `/driverDeliveryPage` |
| Products | `Productlist` / `Productcreate` / `Customproductcreate` |
| Sales reports | `SalesReportPage` |
| Audit | `AuditLogPage` |
| Company settings | `CompanySettingPage` |

---

## 10. Firestore Collections

| Collection | Purpose |
|------------|---------|
| `orders` | Order header: customer, delivery, status, totals, payment |
| `order_items` | Line items: product, qty, price, subtotal |
| `product` | Catalog: name, price, SKU, image, category |
| `users` | Staff: role, company link |
| `companies` | Multi-store / company config |
| `audit_logs` | Admin activity trail |
| `counters` | Order ID / sequence counters |

---

## 11. Custom Actions (Export / Print)

| Action | Purpose |
|--------|---------|
| `print_order_receipt_esc_pos` | Bluetooth thermal receipt |
| `export_orders_to_csv` | Export orders |
| `export_order_items_final_csv` | Export order line items |
| `export_orders_items_pickup_csv` | Pick-up / delivery export |

---

*Generated from TFG VDAY codebase. Mermaid diagrams render in GitHub, VS Code, and Cursor.*
