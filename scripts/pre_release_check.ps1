# Pre-release safety checks (run before production deploy).
# Requires: Node 20+, Java 21 (Firebase emulators), production service account for verify step.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts\pre_release_check.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\pre_release_check.ps1 -Full

param(
  [switch]$Full
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location (Join-Path $root "firebase")

Write-Host "=== Pre-release: Firebase rules tests ===" -ForegroundColor Cyan
npm run test:firebase
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Full) {
  Write-Host "=== Pre-release: verify companyRef (production) ===" -ForegroundColor Cyan
  npm run verify:company-ref:production
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host ""
Write-Host "Pre-release checks passed." -ForegroundColor Green
Write-Host "Deploy order:" -ForegroundColor Yellow
Write-Host "  1. cd firebase && npm run deploy:rules:production"
Write-Host "  2. cd .. && powershell -File scripts\deploy_production_web.ps1"
Write-Host "Optional staging: `$env:STAGING_ADMIN_PASSWORD=... ; cd firebase ; npm run smoke:staging"
