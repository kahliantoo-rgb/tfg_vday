import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '/backend/schema/orders_record.dart';
import '/l10n/tr.dart';

const _whatsappBusinessChannel =
    MethodChannel('com.mycompany.tfgvday/whatsapp_business');

String orderRecipientPhone(OrdersRecord order) {
  if (order.recipientPhoneNumber.isNotEmpty) {
    return order.recipientPhoneNumber;
  }
  return order.customerPhoneNumber;
}

bool get isOrderWhatsAppConfirmationEnabled => true;

bool isPickupOrderRecord(OrdersRecord order) {
  final raw = order.pickupDelivery.isNotEmpty
      ? order.pickupDelivery
      : order.orderType;
  if (raw.isEmpty) {
    return false;
  }
  return raw.toLowerCase().contains('pick');
}

String orderDisplayId(OrdersRecord order) =>
    order.orderId.isNotEmpty ? order.orderId : order.reference.id;

/// Professional order confirmation text for WhatsApp.
String buildOrderConfirmationWhatsAppMessage(OrdersRecord order) {
  final orderId = orderDisplayId(order);
  final buffer = StringBuffer()
    ..writeln('Thank you for your purchase. Your order is confirmed.')
    ..writeln()
    ..writeln('Order ID: $orderId');

  if (isPickupOrderRecord(order)) {
    buffer
      ..writeln()
      ..write(
        'This is a pickup order. Please show your Order ID to our staff when you collect your order.',
      );
  }

  return buffer.toString().trim();
}

/// Normalizes a phone string for `https://wa.me/{digits}` (no + prefix).
String? normalizeWhatsAppPhoneNumber(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) {
    return null;
  }
  if (digits.startsWith('+')) {
    digits = digits.substring(1);
  }
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  // Singapore local mobile: 8 digits starting with 8 or 9.
  if (RegExp(r'^[89]\d{7}$').hasMatch(digits)) {
    digits = '65$digits';
  }
  // Local with leading 0: 91234567 -> 6591234567
  if (RegExp(r'^0[89]\d{7}$').hasMatch(digits)) {
    digits = '65${digits.substring(1)}';
  }
  if (digits.length < 8 || digits.length > 15) {
    return null;
  }
  return digits;
}

Uri buildWhatsAppBusinessSendUri({
  required String phone,
  required String message,
}) {
  return Uri.parse(
    'https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}',
  );
}

Uri buildOrderConfirmationWhatsAppUri(OrdersRecord order) {
  final phone = normalizeWhatsAppPhoneNumber(orderRecipientPhone(order))!;
  final message = buildOrderConfirmationWhatsAppMessage(order);
  return buildWhatsAppBusinessSendUri(phone: phone, message: message);
}

Future<bool> launchWhatsAppBusinessSend({
  required String phone,
  required String message,
}) async {
  if (kIsWeb) {
    final uri = buildWhatsAppBusinessSendUri(phone: phone, message: message);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  if (!kIsWeb && Platform.isAndroid) {
    try {
      final launched = await _whatsappBusinessChannel.invokeMethod<bool>(
        'launchSend',
        <String, String>{
          'phone': phone,
          'text': message,
        },
      );
      return launched ?? false;
    } on PlatformException {
      return false;
    }
  }

  if (!kIsWeb && Platform.isIOS) {
    final uri = Uri.parse(
      'whatsapp-business://send?phone=$phone&text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  final uri = buildWhatsAppBusinessSendUri(phone: phone, message: message);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> launchOrderConfirmationWhatsApp({
  required BuildContext context,
  required OrdersRecord order,
}) async {
  if (!isOrderWhatsAppConfirmationEnabled) {
    return false;
  }

  final phone = normalizeWhatsAppPhoneNumber(orderRecipientPhone(order));
  if (phone == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'order.whatsapp.phoneInvalid')),
        ),
      );
    }
    return false;
  }

  final message = buildOrderConfirmationWhatsAppMessage(order);
  try {
    final launched = await launchWhatsAppBusinessSend(
      phone: phone,
      message: message,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'order.whatsapp.businessOpenFailed')),
        ),
      );
    }
    return launched;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'order.whatsapp.businessOpenFailed')),
        ),
      );
    }
    return false;
  }
}
