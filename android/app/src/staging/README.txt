Place staging google-services.json here before building the staging flavor.

One-time setup:
1. Firebase Console → tfg-vday-record-staging → Project settings → Your apps
2. Add Android app
   Package name: com.tfg_staging
3. Download google-services.json → save as this file:
   android/app/src/staging/google-services.json

Run:
  flutter run --flavor staging --dart-define=APP_ENV=staging

Installs alongside production (com.mycompany.tfgvday) as "TFG Staging".
