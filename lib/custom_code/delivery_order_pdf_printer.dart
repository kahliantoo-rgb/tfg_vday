import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '/backend/audit_log_helpers.dart';
import '/backend/backend.dart';
import '/backend/company_query_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/backend/order_whatsapp_helpers.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/customers_record.dart';
import '/backend/schema/order_item_record.dart';
import '/components/delivery_order_item_table.dart';
import '/backend/payment_method_helpers.dart';
import '/custom_code/pdf_font_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

enum DeliveryPdfKind {
  invoice,
  deliverySlip,
}

/// Generate and print/share delivery invoices as A4 PDF.
class DeliveryOrderPdfPrinter {
  static const String invoiceTitle = 'CASH INVOICE';
  static const String deliverySlipTitle = 'DELIVERY ORDER';
  static const String footerDisclaimer =
      'This is a computer-generated invoice. No signature is required.';
  static const String deliverySlipFooter =
      'Delivery order for fulfilment. Prices are not shown.';

  static void showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  static Future<CompaniesRecord?> resolveInvoiceCompany(
    OrdersRecord order,
  ) async {
    final companyRef = order.companyRef;
    if (companyRef != null) {
      try {
        return await CompaniesRecord.getDocumentOnce(companyRef);
      } catch (_) {
        // Fall back to default company below.
      }
    }
    return getDefaultCompanyOnce();
  }

  static Future<CustomersRecord?> _loadBillingCustomer(
    OrdersRecord order,
  ) async {
    final customerRef = order.customerRef;
    if (customerRef == null) {
      return null;
    }
    try {
      return await CustomersRecord.getDocumentOnce(customerRef);
    } catch (_) {
      return null;
    }
  }

  static Future<pw.MemoryImage?> _loadCompanyLogoImage(
    CompaniesRecord? company,
  ) async {
    final url = company?.logo.trim() ?? '';
    if (url.isEmpty) {
      return null;
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {
      // Logo is optional; continue without it.
    }
    return null;
  }

  static List<String> companyContactLines(CompaniesRecord? company) {
    if (company == null) {
      return const [];
    }
    return [
      if (company.companyUen.isNotEmpty) 'UEN: ${company.companyUen}',
      if (company.companyAddress.isNotEmpty) company.companyAddress,
      if (company.companyPhone.isNotEmpty) 'Tel: ${company.companyPhone}',
    ];
  }

  static List<String> billingAddressLines({
    OrdersRecord? order,
    CustomersRecord? customer,
  }) {
    final name = customer?.name.trim().isNotEmpty == true
        ? customer!.name.trim()
        : (order?.clientName.trim() ?? '');
    final phone = customer?.phone.trim().isNotEmpty == true
        ? customer!.phone.trim()
        : (order?.customerPhoneNumber.trim() ?? '');
    final address = customer?.billingAddress.trim().isNotEmpty == true
        ? customer!.billingAddress.trim()
        : '';
    final uen = customer?.uen.trim().isNotEmpty == true
        ? customer!.uen.trim()
        : '';

    return [
      if (customer?.customerId.isNotEmpty == true)
        'Customer ID: ${customer!.customerId}',
      if (name.isNotEmpty) 'Name: $name',
      if (phone.isNotEmpty) 'Phone: $phone',
      if (uen.isNotEmpty) 'UEN: $uen',
      if (address.isNotEmpty) 'Address: $address',
      if (name.isEmpty && phone.isEmpty && uen.isEmpty && address.isEmpty) '-',
    ];
  }

  static List<String> recipientDetailLines(OrdersRecord order) {
    final deliveryAddress = [
      order.address,
      order.postalCode,
      order.region,
    ].where((part) => part.trim().isNotEmpty).join(', ');
    final deliveryDate = order.deliveryDate != null
        ? dateTimeFormat('yyyy-MM-dd', order.deliveryDate)
        : '-';

    return [
      if (order.recipientName.trim().isNotEmpty)
        'Recipient: ${order.recipientName.trim()}',
      if (orderRecipientPhone(order).trim().isNotEmpty)
        'Phone: ${orderRecipientPhone(order).trim()}',
      if (deliveryAddress.isNotEmpty) 'Address: $deliveryAddress',
      'Delivery date: $deliveryDate',
      if (order.deliveryTimeSlot.trim().isNotEmpty)
        'Time slot: ${order.deliveryTimeSlot.trim()}',
      if (order.cardMessage.trim().isNotEmpty)
        'Message: ${order.cardMessage.trim()}',
    ];
  }

  static pw.Widget _sectionBlock(String title, List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        for (final line in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(line),
          ),
      ],
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
    required OrdersRecord order,
    required List<OrderItemRecord> items,
    CompaniesRecord? company,
    CustomersRecord? customer,
    pw.MemoryImage? logoImage,
    DeliveryPdfKind kind = DeliveryPdfKind.invoice,
    String? deliveryIdOverride,
  }) async {
    final doc = pw.Document();
    final pdfTheme = await loadPdfThemeWithCjk();
    final visibleItems = activeOrderItems(items);
    final includePrices = kind == DeliveryPdfKind.invoice;
    final documentTitle =
        includePrices ? invoiceTitle : deliverySlipTitle;
    final companyName = company?.companyName.trim().isNotEmpty == true
        ? company!.companyName.trim()
        : 'TFG VDAY';
    final orderDate = order.createdTime != null
        ? dateTimeFormat('yyyy-MM-dd', order.createdTime)
        : '-';
    final orderId =
        order.orderId.isNotEmpty ? order.orderId : order.reference.id;
    final deliveryId = deliveryIdOverride?.trim();
    final paymentMethodLabel =
        formatPaymentMethodLabel(order.paymentType);

    double subtotal = 0;
    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: includePrices
            ? [
                _cell('Item', bold: true),
                _cell('Qty', bold: true, align: pw.TextAlign.center),
                _cell('Unit price', bold: true, align: pw.TextAlign.right),
                _cell('Amount', bold: true, align: pw.TextAlign.right),
              ]
            : [
                _cell('Item', bold: true),
                _cell('Qty', bold: true, align: pw.TextAlign.right),
              ],
      ),
    ];

    for (final item in visibleItems) {
      final qty = item.qty;
      final lineTotal =
          item.subtotal > 0 ? item.subtotal : item.price * qty;
      subtotal += lineTotal;
      tableRows.add(
        pw.TableRow(
          children: includePrices
              ? [
                  _itemCell(item),
                  _cell('$qty', align: pw.TextAlign.center),
                  _cell(_money(item.price), align: pw.TextAlign.right),
                  _cell(_money(lineTotal), align: pw.TextAlign.right),
                ]
              : [
                  _itemCell(item),
                  _cell('$qty', align: pw.TextAlign.right),
                ],
        ),
      );
    }

    final total = order.total > 0
        ? order.total
        : (order.totalAmount > 0 ? order.totalAmount : subtotal);

    doc.addPage(
      pw.MultiPage(
        theme: pdfTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        height: 56,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    if (logoImage != null) pw.SizedBox(height: 10),
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    for (final line in companyContactLines(company))
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
                    documentTitle,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Order ID: $orderId'),
                  if (deliveryId != null && deliveryId.isNotEmpty)
                    pw.Text('Delivery ID: $deliveryId'),
                  pw.Text('Date: $orderDate'),
                  if (includePrices)
                    pw.Text('Payment method: $paymentMethodLabel'),
                ],
              ),
            ],
          ),
          if (includePrices) ...[
            _spacedDivider(),
            _sectionBlock(
              'Billing address',
              billingAddressLines(order: order, customer: customer),
            ),
          ],
          _spacedDivider(),
          _sectionBlock(
            'Recipient details',
            recipientDetailLines(order),
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
            columnWidths: includePrices
                ? {
                    0: const pw.FlexColumnWidth(4),
                    1: const pw.FlexColumnWidth(0.8),
                    2: const pw.FlexColumnWidth(1.2),
                    3: const pw.FlexColumnWidth(1.2),
                  }
                : {
                    0: const pw.FlexColumnWidth(5),
                    1: const pw.FlexColumnWidth(0.8),
                  },
            children: tableRows,
          ),
          if (includePrices) ...[
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
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Payment method'),
                        pw.Text(paymentMethodLabel),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              includePrices ? footerDisclaimer : deliverySlipFooter,
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

  static pw.Widget _itemCell(OrderItemRecord item) {
    final name = item.name.isNotEmpty ? item.name : 'Item';
    final remark = DeliveryOrderItemTable.remarkText(item);
    final showRemark = remark != '-';

    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(name),
          if (showRemark) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              remark,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
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

  static Future<pw.Document> _buildDocumentForOrder(
    DocumentReference orderRef, {
    DeliveryPdfKind kind = DeliveryPdfKind.invoice,
    List<OrderItemRecord>? itemsOverride,
    String? deliveryIdOverride,
  }) async {
    final order = await OrdersRecord.getDocumentOnce(orderRef);
    final items = itemsOverride ??
        activeOrderItems(
          await queryOrderItemRecordOnce(
            queryBuilder: (q) => q.where('orderRef', isEqualTo: orderRef),
          ),
        );
    if (items.isEmpty) {
      throw StateError('No order items to print.');
    }

    final company = await resolveInvoiceCompany(order);
    final customer = await _loadBillingCustomer(order);
    final logoImage = await _loadCompanyLogoImage(company);

    return buildDocument(
      order: order,
      items: items,
      company: company,
      customer: customer,
      logoImage: logoImage,
      kind: kind,
      deliveryIdOverride: deliveryIdOverride,
    );
  }

  static Future<pw.Document> _buildDocumentForItems({
    required OrdersRecord order,
    required List<OrderItemRecord> items,
    DeliveryPdfKind kind = DeliveryPdfKind.deliverySlip,
    String? deliveryIdOverride,
  }) async {
    if (items.isEmpty) {
      throw StateError('No order items to print.');
    }

    final company = await resolveInvoiceCompany(order);
    final customer = await _loadBillingCustomer(order);
    final logoImage = await _loadCompanyLogoImage(company);

    return buildDocument(
      order: order,
      items: items,
      company: company,
      customer: customer,
      logoImage: logoImage,
      kind: kind,
      deliveryIdOverride: deliveryIdOverride,
    );
  }

  static Future<void> _layoutPdfForItems(
    BuildContext context, {
    required OrdersRecord order,
    required List<OrderItemRecord> items,
    required DeliveryPdfKind kind,
    required String auditFormat,
    required String filePrefix,
    String? deliveryIdOverride,
  }) async {
    try {
      if (items.isEmpty) {
        throw StateError('Select at least one item to print.');
      }
      final pdfDoc = await _buildDocumentForItems(
        order: order,
        items: items,
        kind: kind,
        deliveryIdOverride: deliveryIdOverride,
      );
      final bytes = await pdfDoc.save();
      final suffix = deliveryIdOverride?.trim().isNotEmpty == true
          ? deliveryIdOverride!.trim()
          : (order.orderId.isNotEmpty ? order.orderId : order.reference.id);
      final fileName = '${filePrefix}_$suffix';

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: fileName,
        format: PdfPageFormat.a4,
      );
      await auditLogPrintReceipt(order: order, format: auditFormat);
    } on StateError catch (e) {
      showSnack(context, e.message);
    } catch (e) {
      showSnack(context, 'PDF print failed: $e');
    }
  }

  static Future<void> _layoutPdfForOrder(
    BuildContext context,
    DocumentReference orderRef, {
    required DeliveryPdfKind kind,
    required String auditFormat,
    required String filePrefix,
  }) async {
    try {
      final order = await OrdersRecord.getDocumentOnce(orderRef);
      final pdfDoc = await _buildDocumentForOrder(orderRef, kind: kind);
      final bytes = await pdfDoc.save();
      final suffix =
          order.orderId.isNotEmpty ? order.orderId : orderRef.id;
      final fileName = '${filePrefix}_$suffix';

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: fileName,
        format: PdfPageFormat.a4,
      );
      await auditLogPrintReceipt(order: order, format: auditFormat);
    } on StateError catch (e) {
      showSnack(context, e.message);
    } catch (e) {
      showSnack(context, 'PDF print failed: $e');
    }
  }

  static Future<void> _sharePdfForOrder(
    BuildContext context,
    DocumentReference orderRef, {
    required DeliveryPdfKind kind,
    required String auditFormat,
    required String filePrefix,
  }) async {
    try {
      final order = await OrdersRecord.getDocumentOnce(orderRef);
      final pdfDoc = await _buildDocumentForOrder(orderRef, kind: kind);
      final bytes = await pdfDoc.save();
      final suffix =
          order.orderId.isNotEmpty ? order.orderId : orderRef.id;
      final fileName = '${filePrefix}_$suffix.pdf';

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
      await auditLogPrintReceipt(order: order, format: auditFormat);
    } on StateError catch (e) {
      showSnack(context, e.message);
    } catch (e) {
      showSnack(context, 'PDF share failed: $e');
    }
  }

  /// Invoice PDF with prices (receipt / billing).
  static Future<void> printDeliveryOrderPdfA4(
    BuildContext context,
    DocumentReference orderRef,
  ) async {
    await _layoutPdfForOrder(
      context,
      orderRef,
      kind: DeliveryPdfKind.invoice,
      auditFormat: 'PDF invoice A4',
      filePrefix: 'invoice',
    );
  }

  /// Delivery slip PDF without prices (driver / fulfilment).
  static Future<void> printDeliverySlipPdfA4(
    BuildContext context,
    DocumentReference orderRef,
  ) async {
    await _layoutPdfForOrder(
      context,
      orderRef,
      kind: DeliveryPdfKind.deliverySlip,
      auditFormat: 'PDF delivery order A4',
      filePrefix: 'delivery_order',
    );
  }

  /// Delivery slip PDF for a subset of line items (partial delivery).
  static Future<void> printDeliverySlipPdfA4ForItems(
    BuildContext context, {
    required OrdersRecord order,
    required List<OrderItemRecord> items,
    String? deliveryIdOverride,
  }) async {
    await _layoutPdfForItems(
      context,
      order: order,
      items: items,
      kind: DeliveryPdfKind.deliverySlip,
      auditFormat: 'PDF partial delivery order A4',
      filePrefix: 'delivery_order',
      deliveryIdOverride: deliveryIdOverride,
    );
  }

  static Future<void> shareDeliveryOrderPdf(
    BuildContext context,
    DocumentReference orderRef,
  ) async {
    await _sharePdfForOrder(
      context,
      orderRef,
      kind: DeliveryPdfKind.invoice,
      auditFormat: 'PDF invoice share',
      filePrefix: 'invoice',
    );
  }

  static Future<void> shareDeliverySlipPdf(
    BuildContext context,
    DocumentReference orderRef,
  ) async {
    await _sharePdfForOrder(
      context,
      orderRef,
      kind: DeliveryPdfKind.deliverySlip,
      auditFormat: 'PDF delivery order share',
      filePrefix: 'delivery_order',
    );
  }
}
