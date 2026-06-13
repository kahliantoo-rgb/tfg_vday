import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import '/backend/firebase/firebase_config.dart';
import '/backend/staff_notice_alert_service.dart';

/// Background FCM handler (app terminated / background isolate).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();

  if (message.notification != null) {
    return;
  }

  await StaffNoticeAlertService.instance.initialize();
  await StaffNoticeAlertService.instance.showPushNotification(
    title: message.data['title'] ?? 'New notice',
    body: message.data['body'] ?? '',
    orderPath: message.data['orderPath'],
    noticeId: message.data['noticeId'],
  );
}
