# Build Flutter web (production Firebase) and deploy to tfg-sales-record hosting.
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Host "Building production web (tfg-sales-record)..."
flutter build web --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$publicDir = Join-Path $repoRoot "firebase\public"
if (-not (Test-Path $publicDir)) {
    New-Item -ItemType Directory -Path $publicDir | Out-Null
}
Write-Host "Copying build/web -> firebase/public ..."
Copy-Item -Recurse -Force (Join-Path $repoRoot "build\web\*") $publicDir

Set-Location (Join-Path $repoRoot "firebase")
Write-Host "Deploying hosting + firestore rules + storage to production..."
npm run deploy:production

Write-Host ""
Write-Host "Done. Open https://tfg-sales-record.web.app and hard-refresh (Ctrl+Shift+R)."
