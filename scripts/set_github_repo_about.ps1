# Sets GitHub repository About section (description, website, topics).
# Requires: gh auth login  (one-time)
# Usage: powershell -ExecutionPolicy Bypass -File scripts/set_github_repo_about.ps1

$ErrorActionPreference = "Stop"

$description = @"
Multi-tenant florist ERP platform built with Flutter and Firebase, featuring POS, CRM, delivery management, Shopify import, and RBAC.
"@.Trim()

$homepage = "https://tfg-sales-record.web.app"

$topics = @(
    "flutter",
    "firebase",
    "firestore",
    "dart",
    "erp",
    "pos",
    "crm",
    "multi-tenant",
    "delivery-management",
    "shopify",
    "cloud-functions"
)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) not found. Install: winget install GitHub.cli"
}

gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Run once: gh auth login"
    exit 1
}

Write-Host "Updating kahliantoo-rgb/tfg_vday About section..."
$topicArgs = $topics | ForEach-Object { "--add-topic"; $_ }
gh repo edit kahliantoo-rgb/tfg_vday `
    --description $description `
    --homepage $homepage `
    @topicArgs

Write-Host "Done. Verify: https://github.com/kahliantoo-rgb/tfg_vday"
