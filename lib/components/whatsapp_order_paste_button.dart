import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '/backend/schema/order_item_record.dart';
import '/backend/custom_product_helpers.dart';
import '/backend/order_navigation_helpers.dart';
import '/backend/order_whatsapp_import_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

/// Dialog pre-filled from clipboard; user reviews and confirms with OK.
Future<String?> showWhatsAppOrderPasteDialog(BuildContext context) async {
  final clipboard = await Clipboard.getData('text/plain');
  final initialText = clipboard?.text?.trim() ?? '';
  final controller = TextEditingController(text: initialText);
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Paste WhatsApp order'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 12,
          minLines: 6,
          decoration: InputDecoration(
            hintText: initialText.isEmpty
                ? 'Clipboard is empty. Paste the WhatsApp message here, then tap OK.'
                : 'Review the message below, edit if needed, then tap OK.',
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isEmpty) {
              return;
            }
            Navigator.pop(dialogContext, text);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// Opens a paste dialog and applies parsed fields or opens an existing order.
class WhatsAppOrderPasteButton extends StatelessWidget {
  const WhatsAppOrderPasteButton({
    super.key,
    this.orderRef,
    this.onDetailsParsed,
    this.onReferencePhotoUploaded,
    this.onDashboardImport,
    this.fullWidth = false,
    this.label = 'Paste from WhatsApp',
  });

  final DocumentReference? orderRef;
  final void Function(WhatsAppParsedOrderDetails details)? onDetailsParsed;
  final void Function(String imageUrl, DocumentReference orderItemRef)?
      onReferencePhotoUploaded;
  final Future<void> Function()? onDashboardImport;
  final bool fullWidth;
  final String label;

  Future<void> _maybePromptReferencePhotoUpload(
    BuildContext context,
    WhatsAppParsedOrderDetails parsed,
  ) async {
    if (!parsed.needsReferencePhoto || orderRef == null) {
      return;
    }

    final uploadNow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reference photo'),
        content: const Text(
          'This WhatsApp message mentions a photo (如图). '
          'Upload the reference photo now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Upload Photo'),
          ),
        ],
      ),
    );
    if (uploadNow != true || !context.mounted) {
      return;
    }

    final itemRef = OrderItemRecord.collection.doc();
    final imageUrl = await pickAndUploadCustomProductImage(
      context: context,
      orderItemId: itemRef.id,
    );
    if (imageUrl == null || !context.mounted) {
      return;
    }

    onReferencePhotoUploaded?.call(imageUrl, itemRef);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reference photo uploaded.')),
    );
  }

  Future<void> _handlePaste(BuildContext context) async {
    if (!isWhatsAppOrderImportEnabled) {
      return;
    }

    if (onDashboardImport != null) {
      await onDashboardImport!();
      return;
    }

    final text = await showWhatsAppOrderPasteDialog(context);
    if (text == null || !context.mounted) {
      return;
    }

    await _processWhatsAppPasteText(context, text);
  }

  Future<void> _processWhatsAppPasteText(
    BuildContext context,
    String text,
  ) async {
    final parsed = parseWhatsAppOrderText(text);
    if (parsed.orderId != null) {
      final order = await findOrderByOrderId(parsed.orderId!);
      if (order != null) {
        if (context.mounted) {
          openOrderDetail(context, order.reference);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opened order ${parsed.orderId}')),
          );
        }
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order ID ${parsed.orderId} was not found in this company.',
            ),
          ),
        );
      }
      if (parsed.hasFormFields) {
        onDetailsParsed?.call(parsed);
        await _maybePromptReferencePhotoUpload(context, parsed);
      }
      return;
    }

    if (parsed.hasFormFields) {
      onDetailsParsed?.call(parsed);
      await _maybePromptReferencePhotoUpload(context, parsed);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pasted order details into the form.'),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not read an order from the message. '
            'Include “Order ID: TFG-…” or labeled customer details.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isWhatsAppOrderImportEnabled) {
      return const SizedBox.shrink();
    }

    return FFButtonWidget(
      onPressed: () => _handlePaste(context),
      text: label,
      icon: const FaIcon(
        FontAwesomeIcons.whatsapp,
        size: 18.0,
        color: Colors.white,
      ),
      options: FFButtonOptions(
        width: fullWidth ? double.infinity : null,
        height: 44.0,
        padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
        color: const Color(0xFF25D366),
        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
              color: Colors.white,
              letterSpacing: 0.0,
            ),
        elevation: 0.0,
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}

void applyWhatsAppParsedDetailsToCreateOrderForm({
  required WhatsAppParsedOrderDetails details,
  required TextEditingController clientNameController,
  required TextEditingController recipientNameController,
  required TextEditingController phoneController,
  required TextEditingController addressController,
  required TextEditingController postalCodeController,
  required TextEditingController regionController,
  required TextEditingController deliveryTimeSlotController,
  required TextEditingController cardMessageController,
  required void Function(DateTime? date) setDeliveryDate,
  required void Function(String? value) setOrderType,
  void Function(String? productHint, double? productPrice)? setProductHint,
}) {
  if (details.clientName != null) {
    clientNameController.text = details.clientName!;
  }
  if (details.recipientName != null) {
    recipientNameController.text = details.recipientName!;
  }
  if (details.phone != null) {
    phoneController.text = details.phone!;
  }
  if (details.address != null) {
    addressController.text = details.address!;
  }
  if (details.postalCode != null) {
    postalCodeController.text = details.postalCode!;
  }
  if (details.region != null) {
    regionController.text = details.region!;
  }
  deliveryTimeSlotController.text =
      resolveWhatsAppDeliveryTimeSlot(details.deliveryTimeSlot);
  if (details.cardMessage != null) {
    cardMessageController.text = details.cardMessage!;
  }
  if (details.deliveryDate != null) {
    setDeliveryDate(details.deliveryDate);
  }
  setOrderType(resolveWhatsAppImportOrderType(details.orderType));
  setProductHint?.call(details.productHint, details.productPrice);
}
