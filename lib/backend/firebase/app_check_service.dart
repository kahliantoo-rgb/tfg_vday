import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '/backend/observability/app_logger.dart';

/// reCAPTCHA v3 site key from Firebase Console → App Check → Web app.
/// Web build: `--dart-define=APP_CHECK_RECAPTCHA_SITE_KEY=...`
const _recaptchaSiteKey = String.fromEnvironment(
  'APP_CHECK_RECAPTCHA_SITE_KEY',
  defaultValue: '',
);

/// Activates Firebase App Check after [Firebase.initializeApp].
///
/// Enforcement is configured in Firebase Console (start in monitoring mode).
/// Shopify webhooks and Firestore triggers do not use App Check tokens.
Future<void> initAppCheck() async {
  try {
    if (kIsWeb) {
      if (_recaptchaSiteKey.isEmpty) {
        AppLogger.warn(
          'App Check skipped on web: set APP_CHECK_RECAPTCHA_SITE_KEY',
        );
        return;
      }
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(_recaptchaSiteKey),
      );
      return;
    }

    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );

    if (kDebugMode) {
      AppLogger.info(
        'App Check debug provider active — register debug token in Firebase Console if needed',
      );
    }
  } catch (error, stackTrace) {
    AppLogger.error('App Check activation failed', error: error, stackTrace: stackTrace);
  }
}
