import 'dart:html' as html;

Future<void> requestWebNotificationPermission() async {
  if (!html.Notification.supported) {
    return;
  }
  if (html.Notification.permission != 'granted') {
    await html.Notification.requestPermission();
  }
}

Future<void> showWebBrowserNotification({
  required String title,
  required String body,
}) async {
  if (!html.Notification.supported) {
    return;
  }
  if (html.Notification.permission != 'granted') {
    await requestWebNotificationPermission();
  }
  if (html.Notification.permission == 'granted') {
    html.Notification(title, body: body.replaceAll('\n', ' · '));
  }
}
