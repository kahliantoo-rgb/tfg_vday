import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import '/backend/observability/app_logger.dart';
import '/backend/observability/performance_baselines.dart';

/// Initializes Crashlytics + Performance and exposes trace helpers.
class ObservabilityService {
  ObservabilityService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!kIsWeb) {
      await _initCrashlytics();
    }

    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    AppLogger.info('Observability initialized');
  }

  static Future<void> _initCrashlytics() async {
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    FlutterError.onError = (details) {
      crashlytics.recordFlutterFatalError(details);
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Runs [action] inside a Firebase Performance trace.
  static Future<T> trace<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String>? attributes,
  }) async {
    final perfTrace = FirebasePerformance.instance.newTrace(name);

    attributes?.forEach((key, value) {
      perfTrace.putAttribute(key, value);
    });
    final baseline = PerformanceBaselines.p95Ms[name];
    if (baseline != null) {
      perfTrace.putAttribute('baseline_p95_ms', '$baseline');
    }

    await perfTrace.start();
    final stopwatch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      stopwatch.stop();
      perfTrace.putAttribute('duration_ms', '${stopwatch.elapsedMilliseconds}');
      await perfTrace.stop();
    }
  }
}
