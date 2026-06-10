# Clean rebuild staging APK (side-by-side TFG Staging app).
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

Write-Host "Cleaning previous build artifacts..." -ForegroundColor Cyan
flutter clean
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Fetching dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Building staging APK (APP_ENV=staging)..." -ForegroundColor Cyan
flutter build apk --release --flavor staging --dart-define=APP_ENV=staging --build-name=1.0.3 --build-number=4
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$src = Join-Path $repoRoot "build\app\outputs\flutter-apk\app-staging-release.apk"
$dest = Join-Path $repoRoot "build\app\outputs\flutter-apk\TFG-VDAY-v1.0.3-staging.apk"
Copy-Item -Force $src $dest

Write-Host ""
Write-Host "Staging APK ready:" -ForegroundColor Green
Write-Host "  $dest"
Write-Host ""
Write-Host "App name: TFG Staging | version in settings: 1.0.3-staging"
Write-Host "Dashboard title should show v1.0.3 (4) and bell icon in app bar."
