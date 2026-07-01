import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/operation_reminder_copy.dart';
import '/backend/dashboard_order_stats_helpers.dart';
import '/backend/schema/staff_notices_record.dart';
import '/backend/staff_notice_helpers.dart';
import '/backend/web_notification_helper.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';

const _androidChannelId = 'tfg_staff_notices';
const _androidChannelName = 'Staff notices';

class StaffNoticeAlertService {
  StaffNoticeAlertService._();

  static final StaffNoticeAlertService instance = StaffNoticeAlertService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final List<StaffNoticesRecord> _pendingDialogs = [];
  bool _dialogShowing = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (kIsWeb) {
      await requestWebNotificationPermission();
      _initialized = true;
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: 'New order and delivery assignment alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
    }

    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    _initialized = true;
  }

  Future<void> alertForNotice(StaffNoticesRecord notice) async {
    await playAlertFeedback();
    if (kIsWeb) {
      await showWebBrowserNotification(
        title: staffNoticeTitle(notice),
        body: staffNoticeBody(notice),
      );
    } else {
      await _showSystemNotification(notice);
    }
    _enqueueInAppDialog(notice);
  }

  Future<void> showPushNotification({
    required String title,
    required String body,
    String? orderPath,
    String? navTarget,
    String? noticeId,
  }) async {
    if (!_initialized) {
      return;
    }
    if (kIsWeb) {
      await showWebBrowserNotification(title: title, body: body);
      return;
    }

    await playAlertFeedback();
    await _notifications.show(
      id: (noticeId ?? title).hashCode,
      title: title,
      body: body.replaceAll('\n', ' · '),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: 'New order and delivery assignment alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: _encodeNotificationPayload(
        orderPath: orderPath,
        navTarget: navTarget,
      ),
    );
  }

  String _encodeNotificationPayload({
    String? orderPath,
    String? navTarget,
  }) {
    if (orderPath != null && orderPath.isNotEmpty) {
      return orderPath;
    }
    if (navTarget != null && navTarget.isNotEmpty) {
      return encodeStaffNoticeNavPayload(navTarget);
    }
    return '';
  }

  void navigateFromNoticePayload(String payload) {
    final navTarget = decodeStaffNoticeNavTarget(payload);
    if (navTarget != null) {
      navigateToNoticeTarget(navTarget);
      return;
    }
    navigateToOrderPath(payload);
  }

  void navigateToNoticeTarget(String navTarget) {
    if (navTarget.isEmpty || !loggedIn) {
      return;
    }
    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }
    switch (navTarget) {
      case StaffNoticeNavTarget.tomorrowPreparation:
        unawaited(
          openDashboardFilteredOrderList(
            context,
            DashboardOrderListFilter.tomorrowDeliveryOrders,
          ),
        );
        break;
    }
  }

  void navigateToOrderPath(String orderPath) {
    if (orderPath.isEmpty || !loggedIn) {
      return;
    }
    final orderRef = FirebaseFirestore.instance.doc(orderPath);
    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }
    context.pushNamed(
      OrderDetailPageWidget.routeName,
      queryParameters: {
        'orderRef': serializeParam(
          orderRef,
          ParamType.DocumentReference,
        )!,
      },
      extra: {'orderRef': orderRef},
    );
  }

  Future<void> playAlertFeedback() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // Some platforms do not support system sounds.
    }
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> _showSystemNotification(StaffNoticesRecord notice) async {
    if (!_initialized || kIsWeb) {
      return;
    }

    final body = staffNoticeBody(notice).replaceAll('\n', ' · ');
    await _notifications.show(
      id: notice.reference.id.hashCode,
      title: staffNoticeTitle(notice),
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: 'New order and delivery assignment alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: _encodeNotificationPayload(
        orderPath: notice.orderRef?.path,
        navTarget: notice.hasNavTarget() ? notice.navTarget : null,
      ),
    );
  }

  void _enqueueInAppDialog(StaffNoticesRecord notice) {
    _pendingDialogs.add(notice);
    _drainDialogQueue();
  }

  Future<void> _drainDialogQueue() async {
    if (_dialogShowing || _pendingDialogs.isEmpty || !loggedIn) {
      return;
    }
    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    _dialogShowing = true;
    final notice = _pendingDialogs.removeAt(0);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.notifications_active_outlined, size: 36),
            title: Text(staffNoticeTitle(notice, dialogContext)),
            content: Text(staffNoticeBody(notice, dialogContext)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Later'),
              ),
              if (notice.hasOrderRef())
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await markStaffNoticeRead(notice.reference);
                    final navContext = appNavigatorKey.currentContext;
                    if (navContext == null || !navContext.mounted) {
                      return;
                    }
                    navContext.pushNamed(
                      OrderDetailPageWidget.routeName,
                      queryParameters: {
                        'orderRef': serializeParam(
                          notice.orderRef,
                          ParamType.DocumentReference,
                        )!,
                      },
                      extra: {'orderRef': notice.orderRef},
                    );
                  },
                  child: const Text('View order'),
                )
              else if (notice.hasNavTarget())
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await markStaffNoticeRead(notice.reference);
                    navigateToNoticeTarget(notice.navTarget);
                  },
                  child: const Text('View schedule'),
                ),
            ],
          );
        },
      );
    } finally {
      _dialogShowing = false;
      if (_pendingDialogs.isNotEmpty) {
        await _drainDialogQueue();
      }
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }
    navigateFromNoticePayload(payload);
  }
}
