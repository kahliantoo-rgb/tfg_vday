# Sync tfg_vday source to Desktop\ERP order management (excludes firebase/database).
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $env:USERPROFILE "Desktop\ERP order management"

if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest | Out-Null
}

Write-Host "Syncing $repoRoot -> $dest (excluding firebase/database)..." -ForegroundColor Cyan

$excludeDirs = @(
    'build',
    '.dart_tool',
    '.git',
    'firebase',
    'node_modules',
    '.idea',
    '.gradle',
    'android\.gradle',
    'android\app\.cxx'
)

$args = @(
    $repoRoot,
    $dest,
    '/E',
    '/NFL', '/NDL', '/NJH', '/NJS', '/NC', '/NS', '/NP'
)
foreach ($dir in $excludeDirs) {
    $args += '/XD'
    $args += $dir
}

& robocopy @args
$code = $LASTEXITCODE
if ($code -ge 8) {
    Write-Error "Robocopy failed with exit code $code"
}

$firebaseDest = Join-Path $dest 'firebase'
if (Test-Path $firebaseDest) {
    Remove-Item -Recurse -Force $firebaseDest
    Write-Host "Removed firebase/ from desktop copy." -ForegroundColor Yellow
}
Write-Host "Desktop ERP folder updated." -ForegroundColor Green
