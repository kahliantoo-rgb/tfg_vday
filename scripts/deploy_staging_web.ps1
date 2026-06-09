# Build Flutter web (staging Firebase) and deploy to Firebase Hosting.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

Write-Host "Building Flutter web (APP_ENV=staging)..." -ForegroundColor Cyan
flutter build web --release --dart-define=APP_ENV=staging
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$publicDir = Join-Path $repoRoot "firebase\public"
if (Test-Path $publicDir) {
    Remove-Item -Recurse -Force $publicDir
}
New-Item -ItemType Directory -Force -Path $publicDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $repoRoot "build\web\*") $publicDir

Write-Host "Deploying to Firebase Hosting (staging)..." -ForegroundColor Cyan
Set-Location (Join-Path $repoRoot "firebase")
npm run bootstrap:staging
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
npm run check:storage:staging
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Staging Storage is not enabled yet - photo uploads will fail until you complete the steps above." -ForegroundColor Yellow
}
npm run deploy:hosting:staging
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Staging web URL: https://tfg-vday-record-staging.web.app" -ForegroundColor Green
Write-Host "Login: staging.admin@tfg-vday.test / StagingTest2026!" -ForegroundColor Green
