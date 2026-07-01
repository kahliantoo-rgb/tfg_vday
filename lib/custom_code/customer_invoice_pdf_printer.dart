import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '/app_branding.dart';
import '/backend/customer_invoice_helpers.dart';
import '/backend/order_id_service.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/customers_record.dart';
import '/backend/payment_method_helpers.dart';
import '/custom_code/delivery_order_pdf_printer.dart';
import '/custom_code/pdf_font_helpers.dart';
import '/custom_code/pdf_logo_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/locale_text.dart';

/// Consolidated credit-customer invoice PDF (multi-order).
class CustomerInvoicePdfPrinter {
  static const footerDisclaimer =
      'This is a computer-generated invoice. No signature is required.';

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _itemCell(CustomerInvoiceLineItem line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(line.productName),
          if (line.remark.isNotEmpty)
            pw.Text(
              line.remark,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _spacedDivider() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 16),
        pw.Divider(),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static Future<pw.Document> buildDocument({
    required String invoiceNumber,
    required CustomersRecord customer,
    required List<CustomerInvoiceLineItem> lines,
    required CustomerInvoiceTotals totals,
    CompaniesRecord? company,
    pw.MemoryImage? logoImage,
    DateTime? invoiceDate,
  }) async {
    final doc = pw.Document();
    final pdfTheme = await loadPdfThemeWithCjk();
    final companyName = company?.companyName.trim().isNotEmpty == true
        ? company!.companyName.trim()
        : kDefaultCompanyDisplayName;
    final dateText = dateTimeFormat(
      'yyyy-MM-dd',
      invoiceDate ?? DateTime.now(),
    );

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _cell('Order ID', bold: true),
          _cell('Item', bold: true),
          _cell('Qty', bold: true, align: pw.TextAlign.center),
          _cell('Unit price', bold: true, align: pw.TextAlign.right),
          _cell('Subtotal', bold: true, align: pw.TextAlign.right),
        ],
      ),
    ];
    for (final line in lines) {
      tableRows.add(
        pw.TableRow(
          children: [
            _cell(line.orderId),
            _itemCell(line),
            _cell('${line.qty}', align: pw.TextAlign.center),
            _cell(_money(line.unitPrice), align: pw.TextAlign.right),
            _cell(_money(line.lineSubtotal), align: pw.TextAlign.right),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        theme: pdfTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => [
          if (logoImage != null) buildPdfCompanyLogoHeader(logoImage),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    for (final line
                        in DeliveryOrderPdfPrinter.companyContactLines(company))
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(line),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Invoice No.: $invoiceNumber'),
                  pw.Text('Date: $dateText'),
                  pw.Text(
                    'Payment method: ${formatPaymentMethodLabel(customer.creditTerm)}',
                  ),
                ],
              ),
            ],
          ),
          _spacedDivider(),
          pw.Text(
            'Billing address',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          for (final line in DeliveryOrderPdfPrinter.billingAddressLines(
            customer: customer,
          ))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(line),
            ),
          _spacedDivider(),
          pw.Text(
            'Items',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.6),
              1: const pw.FlexColumnWidth(2.8),
              2: const pw.FlexColumnWidth(0.7),
              3: const pw.FlexColumnWidth(1.1),
              4: const pw.FlexColumnWidth(1.1),
            },
            children: tableRows,
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 240,
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Subtotal'),
                      pw.Text(_money(totals.subtotal)),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Discount (${totals.discountLabel})'),
                      pw.Text('-${_money(totals.discount)}'),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        _money(totals.total),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Payment method'),
                      pw.Text(formatPaymentMethodLabel(customer.creditTerm)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              footerDisclaimer,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
    return doc;
  }

  static Future<void> printInvoicePdf({
    required BuildContext context,
    required String invoiceNumber,
    required CustomersRecord customer,
    required List<CustomerInvoiceLineItem> lines,
    required CustomerInvoiceTotals totals,
    CompaniesRecord? company,
    DateTime? invoiceDate,
  }) async {
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'invoice.snack.noLineItems')),
        ),
      );
      return;
    }
    try {
      final logoImage = await loadPdfCompanyLogoImage(company);
      final pdfDoc = await buildDocument(
        invoiceNumber: invoiceNumber,
        customer: customer,
        lines: lines,
        totals: totals,
        company: company,
        logoImage: logoImage,
        invoiceDate: invoiceDate,
      );
      final bytes = await pdfDoc.save();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: invoiceNumber,
        format: PdfPageFormat.a4,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice $invoiceNumber sent to printer.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice print failed: $error')),
        );
      }
    }
  }

  static Future<void> shareInvoicePdf({
    required BuildContext context,
    required String invoiceNumber,
    required CustomersRecord customer,
    required List<CustomerInvoiceLineItem> lines,
    required CustomerInvoiceTotals totals,
    CompaniesRecord? company,
    DateTime? invoiceDate,
  }) async {
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'invoice.snack.noLineItems')),
        ),
      );
      return;
    }
    try {
      final logoImage = await loadPdfCompanyLogoImage(company);
      final pdfDoc = await buildDocument(
        invoiceNumber: invoiceNumber,
        customer: customer,
        lines: lines,
        totals: totals,
        company: company,
        logoImage: logoImage,
        invoiceDate: invoiceDate,
      );
      final bytes = await pdfDoc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: '$invoiceNumber.pdf',
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice share failed: $error')),
        );
      }
    }
  }
}
