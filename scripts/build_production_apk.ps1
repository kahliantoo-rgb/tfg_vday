# Clean rebuild production APK — avoids stale Gradle/Dart cache shipping old UI.
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

Write-Host "Building production APK (release)..." -ForegroundColor Cyan
flutter build apk --release --flavor production --build-name=1.0.3 --build-number=11
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$src = Join-Path $repoRoot "build\app\outputs\flutter-apk\app-production-release.apk"
$dest = Join-Path $repoRoot "build\app\outputs\flutter-apk\TFG-VDAY-v1.0.3-build11-production.apk"
Copy-Item -Force $src $dest

Write-Host ""
Write-Host "Production APK ready:" -ForegroundColor Green
Write-Host "  $dest"
Write-Host ""
Write-Host "Install on phone, then confirm Dashboard title shows v1.0.3 (11)."
