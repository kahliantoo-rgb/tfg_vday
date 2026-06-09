import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/backend/order_whatsapp_helpers.dart';
import '/backend/schema/customers_record.dart';

class CustomerBroadcastRecipient {
  const CustomerBroadcastRecipient({
    required this.customer,
    required this.phoneDigits,
  });

  final CustomersRecord customer;
  final String phoneDigits;
}

List<CustomerBroadcastRecipient> filterCustomersForBroadcast(
  List<CustomersRecord> customers,
) {
  final recipients = <CustomerBroadcastRecipient>[];
  for (final customer in customers) {
    final phone = normalizeWhatsAppPhoneNumber(customer.phone);
    if (phone == null) {
      continue;
    }
    recipients.add(
      CustomerBroadcastRecipient(
        customer: customer,
        phoneDigits: phone,
      ),
    );
  }
  return recipients;
}

Uri buildCustomerBroadcastWhatsAppUri({
  required String phoneDigits,
  required String message,
}) {
  return Uri.parse(
    'https://wa.me/$phoneDigits?text=${Uri.encodeComponent(message.trim())}',
  );
}

Future<bool> launchCustomerBroadcastWhatsApp({
  required BuildContext context,
  required CustomerBroadcastRecipient recipient,
  required String message,
}) async {
  final uri = buildCustomerBroadcastWhatsAppUri(
    phoneDigits: recipient.phoneDigits,
    message: message,
  );
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

enum CustomerBroadcastStepAction { send, skip, cancel }

Future<void> runCustomerWhatsAppBroadcast({
  required BuildContext context,
  required List<CustomersRecord> customers,
  required String message,
}) async {
  final recipients = filterCustomersForBroadcast(customers);
  if (recipients.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No customers with a valid phone number to message.'),
        ),
      );
    }
    return;
  }

  var index = 0;
  while (context.mounted && index < recipients.length) {
    final recipient = recipients[index];
    final action = await showDialog<CustomerBroadcastStepAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Broadcast (${index + 1}/${recipients.length})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipient.customer.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(recipient.customer.phone),
              const SizedBox(height: 12),
              Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(dialogContext).hintColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                CustomerBroadcastStepAction.cancel,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                CustomerBroadcastStepAction.skip,
              ),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () async {
                await launchCustomerBroadcastWhatsApp(
                  context: dialogContext,
                  recipient: recipient,
                  message: message,
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(
                    CustomerBroadcastStepAction.send,
                  );
                }
              },
              child: const Text('Open WhatsApp'),
            ),
          ],
        );
      },
    );

    if (action == CustomerBroadcastStepAction.cancel || action == null) {
      return;
    }
    index++;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Broadcast finished for ${recipients.length} customers.'),
      ),
    );
  }
}

Future<void> showCustomerBroadcastDialog({
  required BuildContext context,
  required List<CustomersRecord> customers,
}) async {
  final messageController = TextEditingController();
  final recipientCount = filterCustomersForBroadcast(customers).length;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Broadcast Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: messageController,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'e.g. 优惠',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              recipientCount == 0
                  ? 'No customers with a valid phone number.'
                  : 'Will send to $recipientCount customer(s) via WhatsApp.',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.secondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: recipientCount == 0
                ? null
                : () => Navigator.of(dialogContext).pop(true),
            child: const Text('Start Broadcast'),
          ),
        ],
      );
    },
  );

  final message = messageController.text.trim();
  messageController.dispose();

  if (confirmed != true || message.isEmpty || !context.mounted) {
    if (confirmed == true && message.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message.')),
      );
    }
    return;
  }

  await runCustomerWhatsAppBroadcast(
    context: context,
    customers: customers,
    message: message,
  );
}
