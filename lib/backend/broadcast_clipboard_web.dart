import 'dart:html' as html;

import 'package:flutter/services.dart';

Future<bool> copyRichEmailBroadcastBody({
  required String htmlBody,
  required String plainBody,
}) async {
  try {
    final container = html.DivElement()
      ..style.position = 'fixed'
      ..style.left = '-9999px'
      ..style.top = '0'
      ..innerHtml = htmlBody;
    html.document.body?.append(container);

    final range = html.document.createRange()..selectNodeContents(container);
    final selection = html.window.getSelection();
    selection?.removeAllRanges();
    selection?.addRange(range);

    final copied = html.document.execCommand('copy');
    container.remove();
    selection?.removeAllRanges();

    if (copied) {
      return true;
    }
  } catch (_) {
    // Fall back to plain text below.
  }

  await Clipboard.setData(ClipboardData(text: plainBody));
  return false;
}
