import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/firebase/app_environment.dart';
import '/backend/staff_notice_alert_service.dart';
import '/flutter_flow/nav/nav.dart';

const _deviceIdPrefsKey = 'fcm_device_id';

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  String? _lastSyncedUid;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (kIsWeb) {
      await StaffNoticeAlertService.instance.initialize();
      AppStateNotifier.instance.addListener(_handleAuthChanged);
      _initialized = true;
      return;
    }

    await StaffNoticeAlertService.instance.initialize();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _initialized = true;
      AppStateNotifier.instance.addListener(_handleAuthChanged);
      return;
    }

    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }

    _tokenRefreshSubscription ??=
        _messaging.onTokenRefresh.listen((_) => syncTokenForCurrentUser());

    AppStateNotifier.instance.addListener(_handleAuthChanged);
    _initialized = true;
    await syncTokenForCurrentUser();
  }

  void _handleAuthChanged() {
    if (loggedIn) {
      unawaited(syncTokenForCurrentUser());
      return;
    }
    if (_lastSyncedUid != null) {
      final uid = _lastSyncedUid!;
      _lastSyncedUid = null;
      unawaited(_removeTokenForUser(uid));
    }
  }

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdPrefsKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated =
        '${DateTime.now().microsecondsSinceEpoch}-${Platform.operatingSystem}';
    await prefs.setString(_deviceIdPrefsKey, generated);
    return generated;
  }

  DocumentReference<Map<String, dynamic>> _tokenDoc(String uid, String deviceId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fcm_tokens')
        .doc(deviceId);
  }

  Future<void> syncTokenForCurrentUser() async {
    if (kIsWeb || !loggedIn || currentUserUid.isEmpty) {
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final uid = currentUserUid;
      final deviceId = await _deviceId();
      await _tokenDoc(uid, deviceId).set(
        {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'app_environment': appEnvironment.name,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      _lastSyncedUid = uid;
    } catch (_) {
      // Permission denied or Play Services unavailable.
    }
  }

  Future<void> _removeTokenForUser(String uid) async {
    if (kIsWeb) {
      return;
    }
    try {
      final deviceId = await _deviceId();
      await _tokenDoc(uid, deviceId).delete();
      await _messaging.deleteToken();
    } catch (_) {
      // Best-effort cleanup on sign-out.
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Foreground alerts are handled by StaffNoticeAlertListener (Firestore).
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final orderPath = message.data['orderPath'];
    final navTarget = message.data['navTarget'];
    if (navTarget != null && navTarget.isNotEmpty) {
      StaffNoticeAlertService.instance.navigateToNoticeTarget(navTarget);
      return;
    }
    if (orderPath == null || orderPath.isEmpty) {
      return;
    }
    StaffNoticeAlertService.instance.navigateToOrderPath(orderPath);
  }

  Future<void> dispose() async {
    AppStateNotifier.instance.removeListener(_handleAuthChanged);
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _initialized = false;
  }
}
