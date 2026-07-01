import 'package:flutter/material.dart';

import '/backend/invoice_list_helpers.dart';
import '/l10n/tr.dart';

/// Localized invoice status label for UI.
String invoiceStatusDisplayLabel(BuildContext context, String status) {
  switch (status) {
    case InvoiceStatus.paid:
      return tr(context, 'invoice.status.paid');
    case InvoiceStatus.voided:
      return tr(context, 'invoice.status.voided');
    case InvoiceStatus.pending:
    default:
      return tr(context, 'invoice.status.pending');
  }
}
