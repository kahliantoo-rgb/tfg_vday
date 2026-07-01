import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '/backend/broadcast_clipboard_helper.dart';
import '/backend/customer_broadcast_image_helpers.dart';
import '/backend/customer_helpers.dart';
import '/backend/order_whatsapp_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/tr.dart';

enum CustomerBroadcastChannel {
  whatsapp,
  email,
}

String customerBroadcastChannelLabel(
  BuildContext context,
  CustomerBroadcastChannel channel,
) {
  switch (channel) {
    case CustomerBroadcastChannel.whatsapp:
      return tr(context, 'customer.broadcast.channelWhatsapp');
    case CustomerBroadcastChannel.email:
      return tr(context, 'customer.broadcast.channelEmail');
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

/// When [selectedCustomerPaths] is empty, broadcasts to [filteredCustomers].
/// Otherwise broadcasts only to selected customers from [allCustomers].
List<CustomersRecord> resolveBroadcastCustomerTargets({
  required List<CustomersRecord> allCustomers,
  required List<CustomersRecord> filteredCustomers,
  required Set<String> selectedCustomerPaths,
}) {
  if (selectedCustomerPaths.isEmpty) {
    return filteredCustomers;
  }
  return allCustomers
      .where((customer) => selectedCustomerPaths.contains(customer.reference.path))
      .toList(growable: false);
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
  return buildWhatsAppBusinessSendUri(
    phone: phoneDigits,
    message: composedMessage,
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
  final composedMessage = buildCustomerBroadcastWhatsAppMessage(
    message: message,
    imageUrl: imageUrl,
  );
  try {
    final launched = await launchWhatsAppBusinessSend(
      phone: recipient.phoneDigits,
      message: composedMessage,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'customer.broadcast.whatsappOpenFailed')),
        ),
      );
    }
    return launched;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'customer.broadcast.whatsappOpenFailed')),
        ),
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
                ? tr(context, 'customer.broadcast.tooManyCopied',
                    params: {'count': '${recipients.length}'})
                : tr(context, 'customer.broadcast.tooManyFilter'),
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
        SnackBar(
          content: Text(tr(context, 'customer.broadcast.emailOpenFailed')),
        ),
      );
    }
    return launched;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'customer.broadcast.emailOpenFailed')),
        ),
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
        SnackBar(
          content: Text(tr(context, 'customer.broadcast.noPhoneToMessage')),
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
          title: Text(
            tr(context, 'customer.broadcast.stepTitle', params: {
              'current': '${index + 1}',
              'total': '${recipients.length}',
            }),
          ),
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
              child: Text(tr(context, 'common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                CustomerBroadcastStepAction.skip,
              ),
              child: Text(tr(context, 'customer.broadcast.skip')),
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
              child: Text(tr(context, 'customer.broadcast.openWhatsapp')),
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
        content: Text(
          tr(context, 'customer.broadcast.finished',
              params: {'count': '${recipients.length}'}),
        ),
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
        SnackBar(
          content: Text(tr(context, 'customer.broadcast.noEmailToMessage')),
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
          ? tr(context, 'customer.broadcast.emailOpenedWithPhoto',
              params: {'count': '${recipients.length}'})
          : tr(context, 'customer.broadcast.emailOpenedWithLink',
              params: {'count': '${recipients.length}'})
      : tr(context, 'customer.broadcast.emailOpenedPlain',
          params: {'count': '${recipients.length}'});

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(snackText)),
  );
}

Future<void> showCustomerBroadcastDialog({
  required BuildContext context,
  required List<CustomersRecord> customers,
  String? selectionLabel,
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
                  ? tr(context, 'customer.broadcast.noPhone')
                  : hasPhoto
                      ? tr(context, 'customer.broadcast.whatsappWithPhoto',
                          params: {'count': '$recipientCount'})
                      : tr(context, 'customer.broadcast.whatsappPlain',
                          params: {'count': '$recipientCount'}),
            CustomerBroadcastChannel.email =>
              recipientCount == 0
                  ? tr(context, 'customer.broadcast.noEmail')
                  : hasPhoto
                      ? tr(context, 'customer.broadcast.emailBccWithPhoto',
                          params: {'count': '$recipientCount'})
                      : tr(context, 'customer.broadcast.emailBccPlain',
                          params: {'count': '$recipientCount'}),
          };

          return AlertDialog(
            title: Text(tr(context, 'customer.broadcast.title')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selectionLabel != null && selectionLabel.isNotEmpty) ...[
                    Text(
                      tr(context, 'customer.broadcast.recipients',
                          params: {'label': selectionLabel}),
                      style: Theme.of(dialogContext).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                  ],
                  SegmentedButton<CustomerBroadcastChannel>(
                    segments: CustomerBroadcastChannel.values
                        .map(
                          (value) => ButtonSegment(
                            value: value,
                            label: Text(
                              customerBroadcastChannelLabel(context, value),
                            ),
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
                      decoration: InputDecoration(
                        labelText: tr(context, 'customer.broadcast.subject'),
                        hintText: tr(context, 'customer.broadcast.subjectHint'),
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
                          ? tr(context, 'customer.broadcast.emailBody')
                          : tr(context, 'customer.broadcast.message'),
                      hintText: channel == CustomerBroadcastChannel.email
                          ? tr(context, 'customer.broadcast.emailBodyHint')
                          : tr(context, 'customer.broadcast.messageHint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(context, 'customer.broadcast.photoOptional'),
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
                          child: Text(
                            tr(context, 'customer.broadcast.previewLoadError'),
                          ),
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
                        label: Text(
                          hasPhoto
                              ? tr(context, 'customer.broadcast.replacePhoto')
                              : tr(context, 'customer.broadcast.uploadPhoto'),
                        ),
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
                          child: Text(tr(context, 'customer.broadcast.removePhoto')),
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
                child: Text(tr(context, 'common.cancel')),
              ),
              FilledButton(
                onPressed: recipientCount == 0 || uploadingImage
                    ? null
                    : () => Navigator.of(dialogContext).pop(true),
                child: Text(tr(context, 'customer.broadcast.start')),
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
      SnackBar(
        content: Text(tr(context, 'customer.broadcast.needContent')),
      ),
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
