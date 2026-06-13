# TFG VDAY

Internal **florist POS and delivery management** app for Valentine's Day peak operations. Built with **Flutter** and **Firebase** (UI originally from FlutterFlow; **this Git repo is the only source of truth**).

Staff use it to handle in-store sales, phone/pre-orders, delivery scheduling, driver handoff, and printing — not a customer-facing shop.

> **FlutterFlow freeze (Strategy A):** Do not re-export code from FlutterFlow into this repo. All changes happen here → CI → deploy. See **[docs/FLUTTERFLOW_FREEZE.md](docs/FLUTTERFLOW_FREEZE.md)**.

## What it does

| Area | Features |
|------|----------|
| **Retail (POS)** | Create orders, select products, **custom products** (optional photo), take payment, print thermal receipts · **Production menu** (florist prep sheet, separate from customer receipt) |
| **Delivery / pick-up** | Customer & delivery details, **recipient phone** vs customer phone, order status tracking, **A4 PDF** delivery orders · **Driver assignments** page with suggested route |
| **Customers** | Create / list / profile · autocomplete on **Create Order Form** · **Broadcast** WhatsApp (one-by-one) or Email BCC with optional **inline photo** |
| **Invoices (credit)** | Invoice list & profile · mark as paid with optional **payment proof** photo |
| **WhatsApp import** | Dashboard **Paste from WhatsApp** — clipboard pre-fill, review dialog, auto **Delivery** order (`TFG-MMMYY-000n`) |
| **Shopify** | Webhook import via Cloud Functions (see [docs/SHOPIFY_WEBHOOK.md](docs/SHOPIFY_WEBHOOK.md)) |
| **Roles & permissions** | 10 staff roles + superadmin · **33 granular permissions** · per-company overrides in Firestore `role_permissions` · matrix UI for Director / Admin / Super Admin |
| **Staff admin** | **User List** (name, role, active status) · **Add Staff** · **Role Permissions** panel · set inactive / activate / delete profiles |
| **Catalog & materials** | Products with categories · **materials** list · product recipes (BOM) · material usage report |
| **Reporting** | Sales dashboard stats · **daily sales report** (PayNow/Cash/Card) · **material usage** · **profit summary** (sales − materials − manual expenses) · CSV export |
| **Order detail** | Collapsible **Activity log** · **Edit Products** inline · **Delivery proof** (driver upload, admin view) · **Production menu** print |
| **Driver workflow** | My Deliveries status chips · **delivery proof photo** on completion · assignments managed on staff **Driver Assignments** page |
| **Printing** | Bluetooth ESC/POS (mobile) · PDF A4 via system print dialog · **colour logo** for PDF; thermal auto-converts at print |
| **Staff notices** | Bell icon in app bar — order-create alerts for florists / managers / directors |
| **Uploads** | All photo uploads auto-compressed to **≤ 2 MB** before Storage write |

## Screenshots

### Dashboard

![Sales dashboard — order counts and quick actions](docs/screenshots/dashboard.png)

### Order Management

![Order list with filters, search, and bulk actions](docs/screenshots/order-management.png)

### Create Order

![Create order form — customer, delivery, and card message](docs/screenshots/create-order.png)

### Delivery Management

![Order detail — timeline, assign driver, edit address/products](docs/screenshots/delivery-management.png)

### POS

![Retail order summary — payment method and checkout](docs/screenshots/pos-order-summary.png)

### PDF Invoice

![A4 delivery invoice (PDF print)](docs/screenshots/pdf-invoice.png)

### Receipt Printing

![Bluetooth thermal receipt preview](docs/screenshots/receipt-printing.png)

### Firebase console

Firestore collections and sample order document (`tfg-sales-record`):

![Firestore collections](docs/screenshots/firebase-collections.png)

![Sample order document fields](docs/screenshots/firebase-order-document.png)

## Documentation

| Doc | Purpose |
|-----|---------|
| **[docs/FLUTTERFLOW_FREEZE.md](docs/FLUTTERFLOW_FREEZE.md)** | **Strategy A** — no FF re-export; protected files; dev workflow |
| **[docs/FEATURES.md](docs/FEATURES.md)** | Feature guide / 功能说明 (EN + 中文) — modules, roles, permissions |
| **[docs/WORKFLOW.md](docs/WORKFLOW.md)** | Full workflows (diagrams, screens, Firestore, printing) |
| **[docs/FIREBASE_STRUCTURE.md](docs/FIREBASE_STRUCTURE.md)** | Firebase projects, services, repo layout, deploy (EN + 中文) |
| **[docs/DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md)** | Firestore schema / 数据库结构 (EN + 中文) — collections, fields, Storage |
| **[docs/TECH_STACK.md](docs/TECH_STACK.md)** | Tech stack / 技术线 (EN + 中文) — architecture, Firebase, CI/CD |
| **[docs/SMOKE_TEST_LOG.md](docs/SMOKE_TEST_LOG.md)** | Test execution log |
| **[docs/RUNBOOK_PEAK_OPERATIONS.md](docs/RUNBOOK_PEAK_OPERATIONS.md)** | Peak on-call (EN) |
| **[docs/RUNBOOK_PEAK_OPERATIONS.zh.md](docs/RUNBOOK_PEAK_OPERATIONS.zh.md)** | Peak on-call (中文) · [PDF](docs/RUNBOOK_PEAK_OPERATIONS.zh.pdf) |
| **[docs/STAGING.md](docs/STAGING.md)** | Staging project + deploy-before-production workflow |
| **[docs/SHOPIFY_WEBHOOK.md](docs/SHOPIFY_WEBHOOK.md)** | Shopify order webhook → Firestore import |
| **[docs/OBSERVABILITY.md](docs/OBSERVABILITY.md)** | Crashlytics, Performance baselines, offline queue |

Topics covered in WORKFLOW:

- Login, roles, and **granular permission matrix** (`role_permissions`)
- Retail vs delivery order flows · **WhatsApp paste import** · **Production menu**
- **Customers** — CRUD, autocomplete, broadcast (WhatsApp + Email with photo)
- **Invoices** — credit billing, mark paid, payment proof
- **Materials & profit** — BOM, usage report, profit summary
- Order status lifecycle (`pending` → `completed`) · **delivery proof**
- **Driver assignments** + driver delivery workflow
- **Staff admin** — User List, Role Permissions, Add Staff
- **Bluetooth thermal** and **PDF A4** printing
- Staging vs production deploy (`scripts/deploy_*_web.ps1`)
- Screen map and Firestore collections

## Live app

| Platform | URL / location |
|----------|----------------|
| **Web (production)** | https://tfg-sales-record.web.app |
| **Web (staging)** | https://tfg-vday-record-staging.web.app — login `staging.admin@tfg-vday.test` / `StagingTest2026!` |
| **Web (local build)** | `build/web` → copy to `firebase/public` for hosting deploy |
| **Android (production)** | `flutter build apk --release --flavor production` → `app-production-release.apk` |
| **Android (staging)** | `flutter build apk --release --flavor staging --dart-define=APP_ENV=staging` → side-by-side **TFG Staging** app |

## Tech stack

- **Flutter** 3.x (stable)  
- **Firebase** — Auth, Firestore, Storage (`tfg-sales-record`)  
- **Key packages** — `go_router`, `cloud_firestore`, `flutter_bluetooth_printer`, `pdf`, `printing`  

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable)  
- Firebase project configured (`google-services.json` / `GoogleService-Info.plist` already in repo)  
- For Android builds: Android SDK  
- For Bluetooth printing: physical Android/iOS device  

### Run locally

```bash
cd tfg_vday
flutter pub get
flutter run -d chrome                              # Web (production Firebase)
flutter run -d chrome --dart-define=APP_ENV=staging # Web (staging Firebase)
flutter run --flavor production -d android         # Android production
flutter run --flavor staging --dart-define=APP_ENV=staging -d android
```

### Build

**Current release:** `v1.0.3 (10)` — visible on Sales Dashboard title after install.

```bash
flutter build web --release                                              # production web
flutter build web --release --dart-define=APP_ENV=staging                # staging web
flutter build apk --release --flavor production --build-name=1.0.3 --build-number=10
flutter build apk --release --flavor staging --dart-define=APP_ENV=staging --build-name=1.0.3 --build-number=10
```

**Windows clean APK scripts:**

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build_production_apk.ps1
powershell -ExecutionPolicy Bypass -File scripts/build_staging_apk.ps1
```

Release outputs:

- Production APK: `build/app/outputs/flutter-apk/app-production-release.apk`
- Staging APK: `build/app/outputs/flutter-apk/app-staging-release.apk`
- Web: `build/web/`

### Deploy Web + Firestore rules

**Windows (recommended):**

```powershell
powershell -ExecutionPolicy Bypass -File scripts/deploy_staging_web.ps1
# smoke test on staging URL, then:
powershell -ExecutionPolicy Bypass -File scripts/deploy_production_web.ps1
```

**Manual (any OS):**

```bash
cd firebase
npm run test:firebase           # emulator gate (also runs in CI)
npm run deploy:staging          # rules + hosting → staging (rehearsal)
npm run deploy:production       # after staging PASS — see docs/STAGING.md
```

Production URL: **https://tfg-sales-record.web.app**  
Staging: **https://tfg-vday-record-staging.web.app** — see [docs/STAGING.md](docs/STAGING.md)

On push to `main`, GitHub Actions also builds the production APK (version read from `lib/app_version.dart`) and uploads it as a versioned workflow artifact (**build-apk** job in [.github/workflows/ci.yml](.github/workflows/ci.yml)).

### Staff admin (admin / superadmin / director)

| Action | Where |
|--------|--------|
| View staff | **Sales Dashboard → Menu → User List** or **Company Profile → View User List** (`/userListPage`) |
| Add staff | **Company Profile → Add Staff** (`/register`) |
| **Role permissions** | User List → shield icon, or `/rolePermissionsPage` (Director / Admin / Super Admin) |
| Deactivate | User List → select users → **Set Inactive** (blocks login; prefer over delete) |
| Reactivate | User List → select → **Activate** |
| Delete profile | User List → select → **Delete** (Firestore `users` doc only; Auth account remains) |

See [docs/WORKFLOW.md §1](docs/WORKFLOW.md#1-system-entry-auth--roles) (roles & permissions) and §8 (staff registration).

### Role permissions

Directors, Admins, and Super Admins can open **Role Permissions** to toggle **33 app permissions** per role (orders, invoices, CSV export, assign driver, etc.). Defaults live in `lib/auth/app_permissions.dart`; overrides are stored in Firestore `role_permissions/{companyId}`. Superadmin is not configurable.

### Customers & broadcast

**Menu → Customers** — tenant-scoped profiles (`name`, `phone`, `email`, `billing_address`). On **Create Order Form**, autocomplete links a customer while **Recipient Phone** stays separate.

**Customer list → Broadcast Message:** choose **WhatsApp** (opens `wa.me` per customer, optional photo URL in message) or **Email 群发** (BCC in mail app; optional photo copied as **inline HTML** — paste into email body). Photos upload to Storage `customer_broadcast_images/`.

### Invoices (credit customers)

**Menu → Invoice List** — view/create/edit credit invoices. **Mark as paid** optionally attaches a **payment proof** photo (`invoice_payment_proof_images/`). Requires invoice permissions (`viewInvoices`, `markInvoicesPaid`, etc.).

### Driver assignments & delivery proof

**Menu → Driver Assignments** (`canAssignDriver`) — pick a driver, see assigned orders for a date range, **suggested route** sorted by delivery date/time slot. Drivers on **My Deliveries** upload **delivery proof** photo when completing an order; staff see proof on **Order Detail**.

### Materials & profit reports

**Menu → Material List** — raw materials with unit cost. Product create/edit links **recipes** (BOM). Reports:

- **Material Usage** — qty consumed from completed orders in date range
- **Profit Summary** — sales − material cost − utility / salary / adhoc expenses (manual fields)

### Production menu (florist prep)

Separate from the customer **receipt**: **Order Detail** or **Retail Summary → Production menu** opens a prep sheet listing line items for florists (no prices). Uses `lib/backend/order_production_menu_helpers.dart`.

### WhatsApp paste import

**Sales Dashboard → Paste from WhatsApp** reads the clipboard, opens a review dialog, then creates a **Delivery** order with a new ID (`TFG-JUN26-0001` style). Parsed fields: recipient name, Hp contact, address, card message, delivery date/time (default slot **09:00-20:00**). Shopify order numbers map to `client_name` on the order only. See [docs/WORKFLOW.md §2.1](docs/WORKFLOW.md#21-whatsapp-paste-import).

### Custom products

On **Product Selection** or **Custom product Form**, tap **Create** → dialog: **Upload Photo** (stores URL on `Order_item.image`) or **Add** (no photo). See [docs/WORKFLOW.md §2](docs/WORKFLOW.md#2-create-order-main-entry).

### Daily sales report

**Sales Dashboard → View Reports** opens the daily report for the selected date:

- Total orders and total sales amount
- Payment breakdown, e.g. **PayNow total: $X.XX** (plus Cash, Card)

Paid orders only (`paymentType` set, not cancelled). See [docs/WORKFLOW.md §8](docs/WORKFLOW.md#8-order-management--reporting).

## Printing quick reference

| Need | Where | Platform |
|------|-------|----------|
| Priced receipt (thermal) | Order detail → **Print invoice or receipt** · Receipt preview → **Print Receipt** | Android / iOS |
| Delivery slip (thermal, no prices) | Delivery order summary → **Print thermal (delivery order)** | Android / iOS |
| Delivery order (A4 PDF) | Delivery summary or receipt preview → **Print PDF (A4)** | Web, mobile, desktop |
| Customer invoice (PDF) | Order detail → **Print invoice or receipt** → PDF | Web, mobile, desktop |
| **Production menu** (florist prep) | Order detail or Retail Summary → **Production menu** | Web, mobile, desktop |

**Company logo:** upload full-colour PNG (≥1200px) in Company Settings. Colour is stored for PDF and previews; Bluetooth thermal receipts convert the logo to sharp monochrome at print time (`lib/custom_code/thermal_logo_helpers.dart`).

See [docs/WORKFLOW.md §7](docs/WORKFLOW.md#7-printing-workflows) for details.

## Project structure (high level)

```
lib/
  auth/            # Roles, permission matrix, route guards
  pages/           # Dashboard, orders, reports, invoices, driver assignments
  pos/             # Retail summary, receipt preview, production menu entry
  delivery/        # Delivery checkout, receipt, A4 print views
  custom_code/     # Bluetooth & PDF printers, CSV exports
  backend/         # Firestore helpers, reports, broadcast, proofs
  backend/schema/  # Firestore models & enums
docs/
  WORKFLOW.md      # System workflows
  screenshots/     # README screenshots
firebase/
  firestore.rules  # Tenant + role security (incl. role_permissions)
  functions/       # Shopify webhook, staff notice push
```

## CI

| Job | What it runs |
|-----|----------------|
| **flutter** | Custom integrity check · `flutter analyze` (errors only) · `flutter test` |
| **firestore-rules** | Firebase emulator + Firestore rules tests |
| **build-apk** | `flutter build apk --flavor production --release` on `main` · version from `app_version.dart` · artifact upload |

## Repository

https://github.com/kahliantoo-rgb/tfg_vday

## License

Private project — internal business use.
