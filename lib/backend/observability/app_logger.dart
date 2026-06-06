import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Central logging facade — debug console in dev, Crashlytics in release (mobile).
class AppLogger {
  AppLogger._();

  static const String _tag = 'TFG';

  static void info(String message, {Map<String, Object?>? context}) {
    _log('INFO', message, context);
  }

  static void warn(String message, {Map<String, Object?>? context}) {
    _log('WARN', message, context);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
    bool fatal = false,
  }) {
    _log('ERROR', message, context, error: error);
    _reportToCrashlytics(message, error, stackTrace, context, fatal: fatal);
  }

  static void _log(
    String level,
    String message,
    Map<String, Object?>? context, {
    Object? error,
  }) {
    final suffix = context == null || context.isEmpty
        ? ''
        : ' ${context.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    final line = '[$_tag][$level] $message$suffix';
    if (error != null) {
      debugPrint('$line\n$error');
    } else {
      debugPrint(line);
    }
  }

  static void _reportToCrashlytics(
    String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context, {
    required bool fatal,
  }) {
    if (kIsWeb) {
      return;
    }
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      if (context != null) {
        for (final entry in context.entries) {
          crashlytics.setCustomKey(
            entry.key,
            entry.value?.toString() ?? 'null',
          );
        }
      }
      if (error != null) {
        crashlytics.recordError(
          error,
          stackTrace ?? StackTrace.current,
          reason: message,
          fatal: fatal,
        );
      } else {
        crashlytics.log(message);
      }
    } catch (_) {
      // Crashlytics unavailable (e.g. tests, misconfigured build).
    }
  }
}
