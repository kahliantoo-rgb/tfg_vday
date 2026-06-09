# Run staging Android app (side-by-side with production APK)
Set-Location (Join-Path $PSScriptRoot "..")
$stagingJson = "android\app\src\staging\google-services.json"
if (-not (Test-Path $stagingJson)) {
    Write-Host "Missing $stagingJson" -ForegroundColor Red
    Write-Host "See android/app/src/staging/README.txt"
    exit 1
}
flutter run --flavor staging --dart-define=APP_ENV=staging @args
