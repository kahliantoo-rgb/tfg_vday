import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/customer_invoice_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CustomerInvoiceGenerateResult {
  const CustomerInvoiceGenerateResult({
    required this.discount,
    required this.printPdf,
  });

  final CustomerInvoiceDiscountInput discount;
  final bool printPdf;
}

Future<CustomerInvoiceGenerateResult?> showCustomerInvoiceGenerateDialog(
  BuildContext context,
) async {
  var discountType = CustomerInvoiceDiscountType.amount;
  final discountController = TextEditingController(text: '0');

  final result = await showDialog<CustomerInvoiceGenerateResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        CustomerInvoiceDiscountInput buildDiscount() {
          final parsed =
              double.tryParse(discountController.text.trim()) ?? 0;
          return CustomerInvoiceDiscountInput(
            type: discountType,
            value: parsed,
          );
        }

        return AlertDialog(
          title: Text(tr(context, 'invoice.generate.title')),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr(context, 'invoice.label.discountOptional')),
                const SizedBox(height: 8),
                SegmentedButton<CustomerInvoiceDiscountType>(
                  segments: const [
                    ButtonSegment(
                      value: CustomerInvoiceDiscountType.percent,
                      label: Text('%'),
                    ),
                    ButtonSegment(
                      value: CustomerInvoiceDiscountType.amount,
                      label: Text('SGD'),
                    ),
                  ],
                  selected: {discountType},
                  onSelectionChanged: (selection) {
                    setDialogState(() {
                      discountType = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: discountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    hintText: discountType ==
                            CustomerInvoiceDiscountType.percent
                        ? tr(context, 'invoice.discount.hintPercent')
                        : tr(context, 'invoice.discount.hintAmount'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr(context, 'common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                CustomerInvoiceGenerateResult(
                  discount: buildDiscount(),
                  printPdf: false,
                ),
              ),
              child: const Text('Share PDF'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                CustomerInvoiceGenerateResult(
                  discount: buildDiscount(),
                  printPdf: true,
                ),
              ),
              child: const Text('Print PDF'),
            ),
          ],
        );
      },
    ),
  );

  discountController.dispose();
  return result;
}
