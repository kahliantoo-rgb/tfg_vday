import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '/backend/broadcast_clipboard_helper.dart';
import '/backend/customer_broadcast_image_helpers.dart';
import '/backend/customer_helpers.dart';
import '/backend/order_whatsapp_helpers.dart';
import '/backend/schema/customers_record.dart';

enum CustomerBroadcastChannel {
  whatsapp,
  email,
}

extension CustomerBroadcastChannelLabel on CustomerBroadcastChannel {
  String get label {
    switch (this) {
      case CustomerBroadcastChannel.whatsapp:
        return 'WhatsApp';
      case CustomerBroadcastChannel.email:
        return 'Email (群发)';
    }
  }
}

class CustomerBroadcastRecipient {
  const CustomerBroadcastRecipient({
    required this.customer,
    required this.phoneDigits,
  });

  final CustomersRecord customer;
  final String phoneDigits;
}

class CustomerEmailBroadcastRecipient {
  const CustomerEmailBroadcastRecipient({
    required this.customer,
    required this.email,
  });

  final CustomersRecord customer;
  final String email;
}

/// mailto URLs longer than this may fail in some browsers/clients.
const kMaxCustomerBroadcastMailtoLength = 2000;

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

List<CustomerEmailBroadcastRecipient> filterCustomersForEmailBroadcast(
  List<CustomersRecord> customers,
) {
  final seenEmails = <String>{};
  final recipients = <CustomerEmailBroadcastRecipient>[];
  for (final customer in customers) {
    final email = normalizeCustomerEmail(customer.email);
    if (email.isEmpty || validateCustomerEmailInput(email) != null) {
      continue;
    }
    if (!seenEmails.add(email)) {
      continue;
    }
    recipients.add(
      CustomerEmailBroadcastRecipient(
        customer: customer,
        email: email,
      ),
    );
  }
  return recipients;
}

String buildCustomerBroadcastWhatsAppMessage({
  required String message,
  String? imageUrl,
}) {
  final trimmedMessage = message.trim();
  final trimmedUrl = imageUrl?.trim() ?? '';
  if (trimmedUrl.isEmpty) {
    return trimmedMessage;
  }
  if (trimmedMessage.isEmpty) {
    return trimmedUrl;
  }
  return '$trimmedMessage\n\n$trimmedUrl';
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

String _escapeHtmlAttr(String value) {
  return _escapeHtml(value).replaceAll("'", '&#39;');
}

String buildCustomerBroadcastEmailHtml({
  required String message,
  String? imageUrl,
}) {
  final trimmedMessage = message.trim();
  final trimmedUrl = imageUrl?.trim() ?? '';
  final messageHtml = trimmedMessage.isEmpty
      ? ''
      : trimmedMessage
          .split('\n')
          .map((line) => '<p>${_escapeHtml(line)}</p>')
          .join();
  final imageHtml = trimmedUrl.isEmpty
      ? ''
      : '<p><img src="${_escapeHtmlAttr(trimmedUrl)}" alt="Promotion" '
          'style="max-width:600px;width:100%;height:auto;display:block;" /></p>';
  return '<html><body>$messageHtml$imageHtml</body></html>';
}

String buildCustomerBroadcastEmailPlain({
  required String message,
  String? imageUrl,
}) {
  final trimmedMessage = message.trim();
  final trimmedUrl = imageUrl?.trim() ?? '';
  if (trimmedUrl.isEmpty) {
    return trimmedMessage;
  }
  if (trimmedMessage.isEmpty) {
    return trimmedUrl;
  }
  return '$trimmedMessage\n\n$trimmedUrl';
}

Uri buildCustomerBroadcastWhatsAppUri({
  required String phoneDigits,
  required String message,
  String? imageUrl,
}) {
  final composedMessage = buildCustomerBroadcastWhatsAppMessage(
    message: message,
    imageUrl: imageUrl,
  );
  return Uri.parse(
    'https://wa.me/$phoneDigits?text=${Uri.encodeComponent(composedMessage)}',
  );
}

Uri buildCustomerBroadcastEmailUri({
  required List<String> bccEmails,
  required String subject,
  required String message,
}) {
  final query = <String, String>{};
  if (bccEmails.isNotEmpty) {
    query['bcc'] = bccEmails.join(',');
  }
  if (subject.trim().isNotEmpty) {
    query['subject'] = subject.trim();
  }
  if (message.trim().isNotEmpty) {
    query['body'] = message.trim();
  }
  return Uri(
    scheme: 'mailto',
    path: '',
    queryParameters: query.isEmpty ? null : query,
  );
}

Future<bool> launchCustomerBroadcastWhatsApp({
  required BuildContext context,
  required CustomerBroadcastRecipient recipient,
  required String message,
  String? imageUrl,
}) async {
  final uri = buildCustomerBroadcastWhatsAppUri(
    phoneDigits: recipient.phoneDigits,
    message: message,
    imageUrl: imageUrl,
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

Future<bool> launchCustomerBroadcastEmail({
  required BuildContext context,
  required List<CustomerEmailBroadcastRecipient> recipients,
  required String subject,
  required String message,
}) async {
  if (recipients.isEmpty) {
    return false;
  }

  final uri = buildCustomerBroadcastEmailUri(
    bccEmails: recipients.map((recipient) => recipient.email).toList(),
    subject: subject,
    message: message,
  );

  if (uri.toString().length > kMaxCustomerBroadcastMailtoLength) {
    final copied = await _copyEmailBroadcastAddresses(context, recipients);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copied
                ? 'Too many recipients for one mail link. '
                    'Copied ${recipients.length} email address(es) to clipboard.'
                : 'Too many recipients for one mail link. '
                    'Try filtering fewer customers.',
          ),
        ),
      );
    }
    return copied;
  }

  try {
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open your email app.')),
      );
    }
    return launched;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open your email app.')),
      );
    }
    return false;
  }
}

Future<bool> _copyEmailBroadcastAddresses(
  BuildContext context,
  List<CustomerEmailBroadcastRecipient> recipients,
) async {
  try {
    await Clipboard.setData(
      ClipboardData(text: recipients.map((r) => r.email).join(', ')),
    );
    return true;
  } catch (_) {
    return false;
  }
}

enum CustomerBroadcastStepAction { send, skip, cancel }

Future<void> runCustomerWhatsAppBroadcast({
  required BuildContext context,
  required List<CustomersRecord> customers,
  required String message,
  String? imageUrl,
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

  final whatsappMessage = buildCustomerBroadcastWhatsAppMessage(
    message: message,
    imageUrl: imageUrl,
  );

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
              if (imageUrl != null && imageUrl.trim().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl.trim(),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                whatsappMessage,
                maxLines: 6,
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
                  imageUrl: imageUrl,
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

Future<void> runCustomerEmailBroadcast({
  required BuildContext context,
  required List<CustomersRecord> customers,
  required String subject,
  required String message,
  String? imageUrl,
}) async {
  final recipients = filterCustomersForEmailBroadcast(customers);
  if (recipients.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No customers with a valid email address to message.'),
        ),
      );
    }
    return;
  }

  final trimmedImageUrl = imageUrl?.trim() ?? '';
  final hasImage = trimmedImageUrl.isNotEmpty;
  var htmlCopied = false;

  if (hasImage) {
    htmlCopied = await copyRichEmailBroadcastBody(
      htmlBody: buildCustomerBroadcastEmailHtml(
        message: message,
        imageUrl: trimmedImageUrl,
      ),
      plainBody: buildCustomerBroadcastEmailPlain(
        message: message,
        imageUrl: trimmedImageUrl,
      ),
    );
  }

  final mailtoMessage = hasImage && htmlCopied
      ? message.trim()
      : buildCustomerBroadcastEmailPlain(
          message: message,
          imageUrl: hasImage ? trimmedImageUrl : null,
        );

  final launched = await launchCustomerBroadcastEmail(
    context: context,
    recipients: recipients,
    subject: subject,
    message: mailtoMessage,
  );

  if (!context.mounted || !launched) {
    return;
  }

  final snackText = hasImage
      ? htmlCopied
          ? 'Opened email with ${recipients.length} BCC recipient(s). '
              'Paste (Ctrl+V / Cmd+V) into the body to embed the photo inline.'
          : 'Opened email with ${recipients.length} BCC recipient(s). '
              'Photo link included in the body.'
      : 'Opened email app with ${recipients.length} recipient(s) in BCC.';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(snackText)),
  );
}

Future<void> showCustomerBroadcastDialog({
  required BuildContext context,
  required List<CustomersRecord> customers,
}) async {
  final messageController = TextEditingController();
  final subjectController = TextEditingController();
  var channel = CustomerBroadcastChannel.whatsapp;
  String? imageUrl;
  var uploadingImage = false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final whatsappCount = filterCustomersForBroadcast(customers).length;
          final emailCount = filterCustomersForEmailBroadcast(customers).length;
          final recipientCount = channel == CustomerBroadcastChannel.whatsapp
              ? whatsappCount
              : emailCount;
          final hasPhoto = imageUrl != null && imageUrl!.trim().isNotEmpty;
          final helperText = switch (channel) {
            CustomerBroadcastChannel.whatsapp =>
              recipientCount == 0
                  ? 'No customers with a valid phone number.'
                  : hasPhoto
                      ? 'Will send to $recipientCount customer(s) via WhatsApp with photo link.'
                      : 'Will send to $recipientCount customer(s) via WhatsApp.',
            CustomerBroadcastChannel.email =>
              recipientCount == 0
                  ? 'No customers with a valid email address.'
                  : hasPhoto
                      ? 'Will open email with $recipientCount BCC recipient(s). '
                          'Paste into body to embed photo inline (not attachment).'
                      : 'Will open your email app with $recipientCount recipient(s) in BCC.',
          };

          return AlertDialog(
            title: const Text('Broadcast Message'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<CustomerBroadcastChannel>(
                    segments: CustomerBroadcastChannel.values
                        .map(
                          (value) => ButtonSegment(
                            value: value,
                            label: Text(value.label),
                            icon: Icon(
                              value == CustomerBroadcastChannel.whatsapp
                                  ? Icons.chat_outlined
                                  : Icons.email_outlined,
                            ),
                          ),
                        )
                        .toList(),
                    selected: {channel},
                    onSelectionChanged: (selection) {
                      setDialogState(() {
                        channel = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (channel == CustomerBroadcastChannel.email) ...[
                    TextField(
                      controller: subjectController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        hintText: 'e.g. Seasonal promotion',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: messageController,
                    autofocus: channel == CustomerBroadcastChannel.whatsapp,
                    minLines: 2,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: channel == CustomerBroadcastChannel.email
                          ? 'Email body'
                          : 'Message',
                      hintText: channel == CustomerBroadcastChannel.email
                          ? 'e.g. Dear customer, ...'
                          : 'e.g. 优惠',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Photo (optional)',
                    style: Theme.of(dialogContext).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (hasPhoto) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl!.trim(),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          alignment: Alignment.center,
                          color: Theme.of(dialogContext)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Text('Could not load preview'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: uploadingImage
                            ? null
                            : () async {
                                setDialogState(() {
                                  uploadingImage = true;
                                });
                                final uploadedUrl =
                                    await pickAndUploadCustomerBroadcastImage(
                                  context: dialogContext,
                                );
                                if (dialogContext.mounted) {
                                  setDialogState(() {
                                    uploadingImage = false;
                                    if (uploadedUrl != null) {
                                      imageUrl = uploadedUrl;
                                    }
                                  });
                                }
                              },
                        icon: uploadingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(hasPhoto ? Icons.refresh : Icons.upload),
                        label: Text(hasPhoto ? 'Replace photo' : 'Upload photo'),
                      ),
                      if (hasPhoto) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: uploadingImage
                              ? null
                              : () {
                                  setDialogState(() {
                                    imageUrl = null;
                                  });
                                },
                          child: const Text('Remove'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    helperText,
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: recipientCount == 0 || uploadingImage
                    ? null
                    : () => Navigator.of(dialogContext).pop(true),
                child: const Text('Start Broadcast'),
              ),
            ],
          );
        },
      );
    },
  );

  final selectedChannel = channel;
  final message = messageController.text.trim();
  final subject = subjectController.text.trim();
  final selectedImageUrl = imageUrl?.trim();
  messageController.dispose();
  subjectController.dispose();

  if (confirmed != true || !context.mounted) {
    return;
  }

  if (message.isEmpty &&
      (selectedImageUrl == null || selectedImageUrl.isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a message or upload a photo.')),
    );
    return;
  }

  switch (selectedChannel) {
    case CustomerBroadcastChannel.whatsapp:
      await runCustomerWhatsAppBroadcast(
        context: context,
        customers: customers,
        message: message,
        imageUrl: selectedImageUrl,
      );
    case CustomerBroadcastChannel.email:
      await runCustomerEmailBroadcast(
        context: context,
        customers: customers,
        subject: subject,
        message: message,
        imageUrl: selectedImageUrl,
      );
  }
}
