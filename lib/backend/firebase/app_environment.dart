/// Build-time environment: production (default) or staging Firebase project.
///
/// Android: `flutter run --flavor staging --dart-define=APP_ENV=staging`
/// Web:    `flutter run -d chrome --dart-define=APP_ENV=staging`
/// App Check (web): `--dart-define=APP_CHECK_RECAPTCHA_SITE_KEY=...`
enum AppEnvironment {
  production,
  staging,
}

const _appEnvName = String.fromEnvironment('APP_ENV', defaultValue: 'production');

AppEnvironment get appEnvironment =>
    _appEnvName == 'staging' ? AppEnvironment.staging : AppEnvironment.production;

bool get isStaging => appEnvironment == AppEnvironment.staging;

String get firebaseProjectId => isStaging ? 'tfg-vday-record-staging' : 'tfg-sales-record';
