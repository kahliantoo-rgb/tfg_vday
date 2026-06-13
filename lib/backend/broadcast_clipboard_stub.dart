import 'package:flutter/services.dart';

Future<bool> copyRichEmailBroadcastBody({
  required String htmlBody,
  required String plainBody,
}) async {
  await Clipboard.setData(ClipboardData(text: plainBody));
  return false;
}
