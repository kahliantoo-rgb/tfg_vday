# Fail if protected custom markers are missing (e.g. after accidental FlutterFlow re-export).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$checks = @(
    @("lib/flutter_flow/nav/nav.dart", "role_route_guard"),
    @("lib/auth/role_route_guard.dart", "kDriverAllowedRoutePaths"),
    @("lib/backend/tenant_context.dart", "class TenantContext"),
    @("lib/backend/order_id_service.dart", "OrderIdService"),
    @("lib/backend/order_status_helpers.dart", "createOrderStatusUpdateData"),
    @("lib/backend/order_delete_service.dart", "deleted_orders"),
    @("lib/custom_code/bluetooth_receipt_printer.dart", "ESC/POS"),
    @("lib/custom_code/delivery_order_pdf_printer.dart", "INVOICE"),
    @("firebase/firestore.rules", "docBelongsToAuthTenant")
)

foreach ($pair in $checks) {
    $file = $pair[0]
    $marker = $pair[1]
    if (-not (Test-Path $file)) {
        Write-Error "Missing protected file: $file"
    }
    $content = Get-Content $file -Raw
    if ($content -notmatch [regex]::Escape($marker)) {
        Write-Error @"
Marker not found in $file
  expected: $marker
  Often caused by a FlutterFlow re-export. See docs/FLUTTERFLOW_FREEZE.md
"@
    }
}

Write-Host "OK: custom code integrity markers present"
