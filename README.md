# TFG VDAY

Internal **florist POS and delivery management** app for Valentine's Day peak operations. Built with **Flutter** and **Firebase** (UI originally from FlutterFlow; **this Git repo is the only source of truth**).

Staff use it to handle in-store sales, phone/pre-orders, delivery scheduling, driver handoff, and printing — not a customer-facing shop.

> **FlutterFlow freeze (Strategy A):** Do not re-export code from FlutterFlow into this repo. All changes happen here → CI → deploy. See **[docs/FLUTTERFLOW_FREEZE.md](docs/FLUTTERFLOW_FREEZE.md)**.

## What it does

| Area | Features |
|------|----------|
| **Retail (POS)** | Create orders, select products, **custom products** (optional photo), take payment, print thermal receipts |
| **Delivery / pick-up** | Customer & delivery details, **recipient phone** vs customer phone, order status tracking, **A4 PDF** delivery orders |
| **Customers** | Create / list / profile · autocomplete on **Create Order Form** · broadcast WhatsApp from customer list |
| **WhatsApp import** | Dashboard **Paste from WhatsApp** — clipboard pre-fill, review dialog, auto **Delivery** order (`TFG-MMMYY-000n`) |
| **Roles** | superadmin (cross-company), admin, senior_florist, driver (each sees relevant screens) |
| **Staff admin** | **User List** (name, role, active status) · **Add Staff** · set inactive / activate / delete profiles |
| **Reporting** | Sales dashboard (tomorrow delivery/total stats), **daily sales report** (PayNow/Cash/Card), CSV export |
| **Order detail** | Collapsible **Activity log** (By {user}) · **Edit Products** inline add panel (catalog grid + custom SKU) |
| **Printing** | Bluetooth ESC/POS (mobile) · PDF A4 via system print dialog (all platforms) |

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
| **[docs/WORKFLOW.md](docs/WORKFLOW.md)** | Full workflows (diagrams, screens, Firestore, printing) |
| **[docs/SMOKE_TEST_LOG.md](docs/SMOKE_TEST_LOG.md)** | Test execution log |
| **[docs/RUNBOOK_PEAK_OPERATIONS.md](docs/RUNBOOK_PEAK_OPERATIONS.md)** | Peak on-call (EN) |
| **[docs/RUNBOOK_PEAK_OPERATIONS.zh.md](docs/RUNBOOK_PEAK_OPERATIONS.zh.md)** | Peak on-call (中文) · [PDF](docs/RUNBOOK_PEAK_OPERATIONS.zh.pdf) |
| **[docs/STAGING.md](docs/STAGING.md)** | Staging project + deploy-before-production workflow |
| **[docs/OBSERVABILITY.md](docs/OBSERVABILITY.md)** | Crashlytics, Performance baselines, offline queue |

Topics covered in WORKFLOW:

- Login, roles, and company selection  
- Retail vs delivery order flows · **WhatsApp paste import**  
- **Customers** — CRUD, autocomplete, broadcast  
- Order status lifecycle (`pending` → `completed`)  
- Driver delivery workflow  
- **Staff admin** — User List, Add Staff, inactive accounts  
- **Order detail** — activity log, inline product add  
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

```bash
flutter build web --release                                              # production web
flutter build web --release --dart-define=APP_ENV=staging                # staging web
flutter build apk --release --flavor production                          # production APK
flutter build apk --release --flavor staging --dart-define=APP_ENV=staging
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

On push to `main`, GitHub Actions also builds the APK and uploads it as a workflow artifact (**build-apk** job in [.github/workflows/ci.yml](.github/workflows/ci.yml)).

### Staff admin (admin / superadmin)

| Action | Where |
|--------|--------|
| View staff | **Sales Dashboard → User List** or **Company Profile → View User List** (`/userListPage`) |
| Add staff | **Company Profile → Add Staff** (`/register`) |
| Deactivate | User List → select users → **Set Inactive** (blocks login; prefer over delete) |
| Reactivate | User List → select → **Activate** |
| Delete profile | User List → select → **Delete** (Firestore `users` doc only; Auth account remains) |

See [docs/WORKFLOW.md §8](docs/WORKFLOW.md#8-order-management--reporting) (staff registration) and screen map §10.

### WhatsApp paste import

**Sales Dashboard → Paste from WhatsApp** reads the clipboard, opens a review dialog, then creates a **Delivery** order with a new ID (`TFG-JUN26-0001` style). Parsed fields: recipient name, Hp contact, address, card message, delivery date/time (default slot **09:00-20:00**). Shopify order numbers map to `client_name` on the order only. See [docs/WORKFLOW.md §2.1](docs/WORKFLOW.md#21-whatsapp-paste-import).

### Customers

**Menu → Create Customer / Customers** — tenant-scoped profiles (`name`, `phone`, `billing_address`). On **Create Order Form**, autocomplete links a customer (`customerRef`, `customer_phone_number`) while **Recipient Phone** stays separate (`recipient_phone_number`).

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
| Small receipt | Receipt preview → pair Bluetooth → **Print Receipt** | Android / iOS |
| Delivery order (A4) | Delivery summary or receipt preview → **Print PDF (A4)** | Web, mobile, desktop |

See [docs/WORKFLOW.md §7](docs/WORKFLOW.md#7-printing-workflows) for details.

## Project structure (high level)

```
lib/
  pages/           # Login, dashboard, order forms, reports, user list
  pos/             # Retail summary & receipt preview
  delivery/        # Delivery checkout, receipt, A4 print views
  custom_code/     # Bluetooth & PDF printers, CSV exports
  backend/schema/  # Firestore models & enums
docs/
  WORKFLOW.md      # System workflows
  screenshots/     # README screenshots
```

## CI

| Job | What it runs |
|-----|----------------|
| **flutter** | Custom integrity check · `flutter analyze` (errors only) · `flutter test` |
| **firestore-rules** | Firebase emulator + Firestore rules tests |
| **build-apk** | `flutter build apk --release` on `main` (artifact upload) |

## Repository

https://github.com/kahliantoo-rgb/tfg_vday

## License

Private project — internal business use.
