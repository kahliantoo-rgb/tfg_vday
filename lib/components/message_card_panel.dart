import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/order_list_display_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Message card with selectable text, copy button, and order ID footer.
class MessageCardPanel extends StatelessWidget {
  const MessageCardPanel({
    super.key,
    required this.order,
    this.borderColor = const Color(0xFFDDD6FE),
    this.textColor,
    this.minHeight = 72.0,
  });

  final OrdersRecord order;
  final Color borderColor;
  final Color? textColor;
  final double minHeight;

  String get _orderId => orderListOrderId(order);

  String get _message {
    final raw = order.cardMessage.trim();
    if (raw.isEmpty) {
      return '-';
    }
    return raw;
  }

  Future<void> _copyToClipboard(
    BuildContext context, {
    required String text,
    required String emptyLabel,
    required String successLabel,
  }) async {
    if (text.isEmpty) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emptyLabel),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successLabel),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String get _fullCardText {
    final messagePart = _message == '-' ? '' : _message;
    if (messagePart.isEmpty && _orderId.isEmpty) {
      return '';
    }
    if (messagePart.isEmpty) {
      return _orderId;
    }
    if (_orderId.isEmpty) {
      return messagePart;
    }
    return '$messagePart\n\n$_orderId';
  }

  Future<void> _copyMessage(BuildContext context) async {
    await _copyToClipboard(
      context,
      text: _fullCardText,
      emptyLabel: 'Message card is empty',
      successLabel: 'Message card copied',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final ink = textColor ?? theme.primaryText;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: borderColor, width: 2.0),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 44.0, 28.0),
            child: SelectableText(
              _message,
              style: GoogleFonts.inter(
                fontSize: 16.0,
                fontWeight: FontWeight.w400,
                color: ink,
                height: 1.5,
              ),
            ),
          ),
          Positioned(
            top: 0.0,
            right: 0.0,
            child: IconButton(
              tooltip: 'Copy message card',
              icon: Icon(
                Icons.copy_rounded,
                size: 18.0,
                color: theme.primary,
              ),
              onPressed: () => _copyMessage(context),
            ),
          ),
          Positioned(
            left: 10.0,
            bottom: 6.0,
            child: Text(
              _orderId,
              style: GoogleFonts.inter(
                fontSize: 10.0,
                fontWeight: FontWeight.w500,
                color: ink.withValues(alpha: 0.55),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header row: gift icon + "Message Card" title.
class MessageCardHeader extends StatelessWidget {
  const MessageCardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Icon(
          Icons.card_giftcard,
          color: theme.tertiary,
          size: 20.0,
        ),
        const SizedBox(width: 8.0),
        Text(
          'Message Card',
          style: GoogleFonts.interTight(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: theme.primary,
          ),
        ),
      ],
    );
  }
}

/// Print-friendly message card (black text, no copy button).
class MessageCardPrintPanel extends StatelessWidget {
  const MessageCardPrintPanel({
    super.key,
    required this.order,
  });

  final OrdersRecord order;

  @override
  Widget build(BuildContext context) {
    final message = order.cardMessage.trim().isEmpty ? '-' : order.cardMessage.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.black, width: 1.0),
      ),
      child: Stack(
        children: [
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 18.0,
              color: Colors.black,
              height: 1.4,
            ),
          ),
          Positioned(
            left: 0.0,
            bottom: 0.0,
            child: Text(
              orderListOrderId(order),
              style: GoogleFonts.inter(
                fontSize: 10.0,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
