# Staging release gate: emulator tests → companyRef verify → deploy → live smoke.
param(
    [switch]$SkipFlutterTest,
    [switch]$SkipDeploy,
    [switch]$SkipLiveSmoke
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$firebaseDir = Join-Path $repoRoot "firebase"

Write-Host "=== TFG VDAY staging deploy + smoke ===" -ForegroundColor Cyan

if (-not $SkipFlutterTest) {
    Write-Host "`n[1/5] Flutter unit tests..." -ForegroundColor Cyan
    Set-Location $repoRoot
    flutter test
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host "`n[1/5] Flutter tests skipped (-SkipFlutterTest)" -ForegroundColor Yellow
}

Write-Host "`n[2/5] Firebase emulator tests (Firestore + Storage rules)..." -ForegroundColor Cyan
Set-Location $firebaseDir
npm run test:firebase
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n[3/5] Verify companyRef backfill on staging..." -ForegroundColor Cyan
npm run verify:company-ref:staging:strict
if ($LASTEXITCODE -ne 0) {
    Write-Host "Backfill required before deploy:" -ForegroundColor Red
    Write-Host "  npm run backfill:company-ref:staging:dry-run" -ForegroundColor Yellow
    Write-Host "  npm run backfill:company-ref:staging" -ForegroundColor Yellow
    exit $LASTEXITCODE
}

if ($SkipDeploy) {
    Write-Host "`n[4/5] Deploy skipped (-SkipDeploy)" -ForegroundColor Yellow
} else {
    Write-Host "`n[4/5] Deploy staging web + rules..." -ForegroundColor Cyan
    Set-Location $repoRoot
    & (Join-Path $repoRoot "scripts\deploy_staging_web.ps1")
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Set-Location $firebaseDir
    Write-Host "Deploying Firestore + Storage rules to staging..." -ForegroundColor Cyan
    npm run deploy:rules:staging:only
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if ($SkipLiveSmoke) {
    Write-Host "`n[5/5] Live smoke skipped (-SkipLiveSmoke)" -ForegroundColor Yellow
} else {
    if (-not $env:STAGING_ADMIN_PASSWORD) {
        Write-Host "`n[5/5] Live smoke skipped — set STAGING_ADMIN_PASSWORD" -ForegroundColor Yellow
    } else {
        Write-Host "`n[5/5] Live staging smoke (Auth + Storage + Hosting)..." -ForegroundColor Cyan
        Set-Location $firebaseDir
        npm run smoke:staging
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
}

Write-Host "`nStaging gate complete." -ForegroundColor Green
Write-Host "URL: https://tfg-vday-record-staging.web.app" -ForegroundColor Green
Write-Host "Manual: Add Staff, Create Order, delivery proof upload" -ForegroundColor Green
