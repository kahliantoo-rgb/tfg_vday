import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '/backend/backend.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/company_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Generate and print/share delivery orders as A4 PDF.
class DeliveryOrderPdfPrinter {
  static void showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  static pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  static Future<String?> _driverName(DocumentReference? driverRef) async {
    if (driverRef == null) return null;
    try {
      final user = await UsersRecord.getDocumentOnce(driverRef);
      if (user.displayName.isNotEmpty) return user.displayName;
      if (user.name.isNotEmpty) return user.name;
      return user.email;
    } catch (_) {
      return null;
    }
  }

  static Future<pw.Document> buildDocument({
    required OrdersRecord order,
    required List<OrderItemRecord> items,
    CompaniesRecord? company,
    String? driverName,
  }) async {
    final doc = pw.Document();
    final companyName = company?.companyName ?? 'TFG VDAY';
    final orderDate = order.createdTime != null
        ? dateTimeFormat('yyyy-MM-dd HH:mm', order.createdTime)
        : '-';
    final deliveryDate = order.deliveryDate != null
        ? dateTimeFormat('yyyy-MM-dd', order.deliveryDate)
        : '-';

    double subtotal = 0;
    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _cell('Item', bold: true),
          _cell('Qty', bold: true, align: pw.TextAlign.center),
          _cell('Unit Price', bold: true, align: pw.TextAlign.right),
          _cell('Subtotal', bold: true, align: pw.TextAlign.right),
        ],
      ),
    ];

    for (final item in items) {
      final qty = item.qty > 0 ? item.qty : 1;
      final lineTotal =
          item.subtotal > 0 ? item.subtotal : item.price * qty;
      subtotal += lineTotal;
      tableRows.add(
        pw.TableRow(
          children: [
            _cell(item.name.isNotEmpty ? item.name : 'Item'),
            _cell('$qty', align: pw.TextAlign.center),
            _cell(_money(item.price), align: pw.TextAlign.right),
            _cell(_money(lineTotal), align: pw.TextAlign.right),
          ],
        ),
      );
    }

    final total = order.total > 0
        ? order.total
        : (order.totalAmount > 0 ? order.totalAmount : subtotal);

    final fullAddress = [
      order.address,
      order.region,
      order.postalCode,
    ].where((s) => s.isNotEmpty).join(', ');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (company != null && company.companyUen.isNotEmpty)
                    pw.Text('UEN: ${company.companyUen}'),
                  if (company != null && company.companyPhone.isNotEmpty)
                    pw.Text(company.companyPhone),
                  if (company != null && company.companyAddress.isNotEmpty)
                    pw.Text(company.companyAddress),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'DELIVERY ORDER',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Order: ${order.orderId.isNotEmpty ? order.orderId : order.reference.id}'),
                  pw.Text('Date: $orderDate'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.SizedBox(height: 16),
          pw.Text(
            'Customer Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _labelValue('Customer Name', order.clientName),
          _labelValue('Phone', order.customerPhoneNumber),
          _labelValue('Delivery Address', fullAddress),
          _labelValue('Delivery Date', deliveryDate),
          _labelValue('Time Slot', order.deliveryTimeSlot),
          _labelValue('Region', order.region),
          if (order.cardMessage.isNotEmpty)
            _labelValue('Card Message', order.cardMessage),
          pw.SizedBox(height: 20),
          pw.Text(
            'Order Items',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: tableRows,
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 220,
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Subtotal'),
                      pw.Text(_money(subtotal)),
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
                        _money(total),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  if (order.paymentType.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Payment'),
                        pw.Text(order.paymentType),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 32),
          pw.Divider(),
          pw.SizedBox(height: 16),
          if (driverName != null && driverName.isNotEmpty)
            _labelValue('Assigned Driver', driverName),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Driver Signature'),
                  pw.SizedBox(height: 40),
                  pw.Container(
                    width: 200,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black),
                      ),
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Date'),
                  pw.SizedBox(height: 40),
                  pw.Container(
                    width: 120,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc;
  }

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

  static Future<void> printDeliveryOrderPdfA4(
    BuildContext context,
    DocumentReference orderRef,
  ) async {
    try {
      final order = await OrdersRecord.getDocumentOnce(orderRef);
      final items = await queryOrderItemRecordOnce(
        queryBuilder: (q) => q.where('orderRef', isEqualTo: orderRef),
      );

      if (items.isEmpty) {
        showSnack(context, 'No order items to print.');
        return;
      }

      final company = await getDefaultCompanyOnce();
      final driverName = await _driverName(order.assignedDriver);

      final pdfDoc = await buildDocument(
        order: order,
        items: items,
        company: company,
        driverName: driverName,
      );

      final bytes = await pdfDoc.save();
      final fileName =
          'delivery_order_${order.orderId.isNotEmpty ? order.orderId : orderRef.id}';

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: fileName,
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      showSnack(context, 'PDF print failed: $e');
    }
  }

  static Future<void> shareDeliveryOrderPdf(
    BuildContext context,
    DocumentReference orderRef,
  ) async {
    try {
      final order = await OrdersRecord.getDocumentOnce(orderRef);
      final items = await queryOrderItemRecordOnce(
        queryBuilder: (q) => q.where('orderRef', isEqualTo: orderRef),
      );

      if (items.isEmpty) {
        showSnack(context, 'No order items to export.');
        return;
      }

      final company = await getDefaultCompanyOnce();
      final driverName = await _driverName(order.assignedDriver);

      final pdfDoc = await buildDocument(
        order: order,
        items: items,
        company: company,
        driverName: driverName,
      );

      final bytes = await pdfDoc.save();
      final fileName =
          'delivery_order_${order.orderId.isNotEmpty ? order.orderId : orderRef.id}.pdf';

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    } catch (e) {
      showSnack(context, 'PDF share failed: $e');
    }
  }
}
