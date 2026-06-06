#!/usr/bin/env bash
# Fail if protected custom markers are missing (e.g. after accidental FlutterFlow re-export).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

check() {
  local file="$1"
  local marker="$2"
  if [[ ! -f "$file" ]]; then
    echo "ERROR: missing protected file: $file"
    exit 1
  fi
  if ! grep -qF "$marker" "$file"; then
    echo "ERROR: marker not found in $file"
    echo "       expected substring: $marker"
    echo "       This often means a FlutterFlow re-export overwrote custom code."
    echo "       See docs/FLUTTERFLOW_FREEZE.md"
    exit 1
  fi
}

check "lib/flutter_flow/nav/nav.dart" "role_route_guard"
check "lib/auth/role_route_guard.dart" "kDriverAllowedRoutePaths"
check "lib/backend/tenant_context.dart" "class TenantContext"
check "lib/backend/order_id_service.dart" "OrderIdService"
check "lib/backend/order_status_helpers.dart" "createOrderStatusUpdateData"
check "lib/backend/order_delete_service.dart" "deleted_orders"
check "lib/custom_code/bluetooth_receipt_printer.dart" "ESC/POS"
check "lib/custom_code/delivery_order_pdf_printer.dart" "INVOICE"
check "firebase/firestore.rules" "docBelongsToAuthTenant"

echo "OK: custom code integrity markers present ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
