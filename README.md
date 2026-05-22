# TFG VDAY

Internal **florist POS and delivery management** app for Valentine's Day peak operations. Built with **Flutter (FlutterFlow)** and **Firebase**.

Staff use it to handle in-store sales, phone/pre-orders, delivery scheduling, driver handoff, and printing — not a customer-facing shop.

## What it does

| Area | Features |
|------|----------|
| **Retail (POS)** | Create orders, select products, take payment, print thermal receipts |
| **Delivery / pick-up** | Customer & delivery details, order status tracking, **A4 PDF** delivery orders |
| **Roles** | Admin, senior florist, driver (each sees relevant screens) |
| **Reporting** | Sales dashboard, reports, CSV export |
| **Printing** | Bluetooth ESC/POS (mobile) · PDF A4 via system print dialog (all platforms) |

## Documentation

Full workflows (diagrams, screens, Firestore, printing):

**[docs/WORKFLOW.md](docs/WORKFLOW.md)**

Topics covered:

- Login, roles, and company selection  
- Retail vs delivery order flows  
- Order status lifecycle (`pending` → `completed`)  
- Driver delivery workflow  
- **Bluetooth thermal** and **PDF A4** printing  
- Screen map and Firestore collections  

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
flutter run -d chrome    # Web
flutter run -d android     # Android (Bluetooth + full features)
```

### Build

```bash
flutter build apk          # Android
flutter build web          # Web
```

## Printing quick reference

| Need | Where | Platform |
|------|-------|----------|
| Small receipt | Receipt preview → pair Bluetooth → **Print Receipt** | Android / iOS |
| Delivery order (A4) | Delivery summary or receipt preview → **Print PDF (A4)** | Web, mobile, desktop |

See [docs/WORKFLOW.md §7](docs/WORKFLOW.md#7-printing-workflows) for details.

## Project structure (high level)

```
lib/
  pages/           # Login, dashboard, order forms, reports
  pos/             # Retail summary & receipt preview
  delivery/        # Delivery checkout, receipt, A4 print views
  custom_code/     # Bluetooth & PDF printers, CSV exports
  backend/schema/  # Firestore models & enums
docs/
  WORKFLOW.md      # System workflows
```

## Repository

https://github.com/kahliantoo-rgb/tfg_vday

## License

Private project — internal business use.
