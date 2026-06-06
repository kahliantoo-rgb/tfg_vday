import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '/backend/offline/offline_flush_service.dart';

/// Watches network changes and triggers offline queue flush when back online.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> start() async {
    if (kIsWeb) {
      // Web offline detection is unreliable via connectivity_plus; rely on
      // Firestore errors + manual retry on next user action.
      return;
    }

    await _subscription?.cancel();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (_isOnline(results)) {
        unawaited(OfflineFlushService.instance.flushPending());
      }
    });

    final current = await Connectivity().checkConnectivity();
    if (_isOnline(current)) {
      await OfflineFlushService.instance.flushPending();
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }
}
