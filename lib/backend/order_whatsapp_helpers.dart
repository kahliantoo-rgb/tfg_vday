import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/backend/schema/orders_record.dart';

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

Uri buildOrderConfirmationWhatsAppUri(OrdersRecord order) {
  final phone = normalizeWhatsAppPhoneNumber(orderRecipientPhone(order))!;
  final message = buildOrderConfirmationWhatsAppMessage(order);
  return Uri.parse(
    'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
  );
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
        const SnackBar(
          content: Text('Customer phone number is missing or invalid.'),
        ),
      );
    }
    return false;
  }

  final uri = buildOrderConfirmationWhatsAppUri(order);
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
    return launched;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
    return false;
  }
}
