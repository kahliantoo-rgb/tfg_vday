import 'package:flutter/material.dart';

const creditPaymentPrefix = 'Credit';

bool isCreditPaymentType(String? paymentType) {
  return paymentType != null &&
      paymentType.trim().toLowerCase().startsWith('credit');
}

String formatCreditPaymentType({required int days}) => 'Credit $days days';

String creditTermShortLabel(String paymentType) {
  final term = paymentType
      .replaceFirst(RegExp(r'^credit\s*', caseSensitive: false), '')
      .trim();
  if (term.isEmpty) {
    return 'Credit';
  }
  if (term.toLowerCase() == 'cash on delivery') {
    return 'COD';
  }
  return term;
}

String? parseCustomCreditTerm(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final lower = trimmed.toLowerCase();
  if (lower == 'cod' ||
      lower.contains('cash on delivery') ||
      lower == 'cash on delivery') {
    return 'Credit Cash on delivery';
  }
  final daysOnly = RegExp(r'^(\d+)\s*$').firstMatch(trimmed);
  if (daysOnly != null) {
    return formatCreditPaymentType(days: int.parse(daysOnly.group(1)!));
  }
  final daysWithSuffix =
      RegExp(r'^(\d+)\s*days?$', caseSensitive: false).firstMatch(trimmed);
  if (daysWithSuffix != null) {
    return formatCreditPaymentType(days: int.parse(daysWithSuffix.group(1)!));
  }
  return 'Credit $trimmed';
}

/// Pick 15 / 30 days or enter custom days / cash on delivery.
Future<String?> showCreditTermPickerDialog(BuildContext context) async {
  final customController = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Credit terms'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('15 days'),
              onTap: () => Navigator.pop(
                dialogContext,
                formatCreditPaymentType(days: 15),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('30 days'),
              onTap: () => Navigator.pop(
                dialogContext,
                formatCreditPaymentType(days: 30),
              ),
            ),
            const Divider(),
            const Text('Custom'),
            const SizedBox(height: 8),
            TextField(
              controller: customController,
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'e.g. 45 days or Cash on delivery',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                final parsed = parseCustomCreditTerm(value);
                if (parsed != null) {
                  Navigator.pop(dialogContext, parsed);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final parsed = parseCustomCreditTerm(customController.text);
            if (parsed == null) {
              return;
            }
            Navigator.pop(dialogContext, parsed);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  customController.dispose();
  return result;
}
