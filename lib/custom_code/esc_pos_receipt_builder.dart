import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '/app_branding.dart';
import '/custom_code/thermal_logo_helpers.dart';
import '/custom_code/thermal_paper_helpers.dart';

import '/backend/audit_log_helpers.dart';
import '/backend/order_whatsapp_helpers.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/order_item_helpers.dart';
import '/backend/order_balance_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/components/receipt_order_item_list.dart';
import '/custom_code/esc_pos_text_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EscPosReceiptBuilder {
  EscPosReceiptBuilder();

  final List<int> _buffer = <int>[];

  List<int> build() => List<int>.from(_buffer);

  void init() {
    _buffer
      ..addAll([0x1B, 0x40])
      ..addAll(escPosEnableChinese);
  }

  Future<void> appendLogoRaster(List<int> rasterBytes) async {
    if (rasterBytes.isEmpty) {
      return;
    }
    _buffer
      ..addAll([0x1B, 0x61, 0x01])
      ..addAll(rasterBytes)
      ..addAll([0x1B, 0x61, 0x00])
      ..add(0x0A);
  }

  Future<void> writeLine(
    String text, {
    bool center = false,
    bool bold = false,
  }) async {
    if (center) {
      _buffer.addAll([0x1B, 0x61, 0x01]);
    }
    if (bold) {
      _buffer.addAll([0x1B, 0x45, 0x01]);
    }
    _buffer.addAll(await encodeEscPosText(text));
    _buffer.add(0x0A);
    if (bold) {
      _buffer.addAll([0x1B, 0x45, 0x00]);
    }
    if (center) {
      _buffer.addAll([0x1B, 0x61, 0x00]);
    }
  }

  Future<void> writeWrapped(String text, {bool center = false}) async {
    for (final line in escPosWrapLines(text)) {
      await writeLine(line, center: center);
    }
  }

  Future<void> divider() async {
    await writeLine('=' * thermalPaperLineWidth());
  }

  Future<void> blankLine() async {
    _buffer.add(0x0A);
  }
}

Future<List<int>?> buildCompanyLogoRaster(CompaniesRecord? company) async {
  final url = company?.logo.trim() ?? '';
  if (url.isEmpty) {
    return null;
  }
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      return null;
    }
    final decoded = img.decodeImage(response.bodyBytes);
    if (decoded == null) {
      return null;
    }
    final prepared = prepareCompanyLogoForThermal(
      decoded,
      dotsPerLine: thermalPaperDotsPerLine(),
    );
    return encodeEscPosRasterImage(prepared);
  } catch (_) {
    return null;
  }
}

String formatOrderDeliveryAddress(OrdersRecord order) {
  return [
    order.address,
    order.postalCode,
    order.region,
  ].where((part) => part.trim().isNotEmpty).join(', ');
}

enum EscPosReceiptFormat {
  receipt,
  deliverySlip,
}

Future<List<int>> buildEscPosDeliverySlipBytes({
  required OrdersRecord order,
  required List<OrderItemRecord> items,
  CompaniesRecord? company,
  String? cashierName,
  String? deliveryIdOverride,
}) =>
    buildEscPosReceiptBytes(
      order: order,
      items: items,
      company: company,
      cashierName: cashierName,
      format: EscPosReceiptFormat.deliverySlip,
      deliveryIdOverride: deliveryIdOverride,
    );

Future<void> _writeEscPosDeliveryDetails(
  EscPosReceiptBuilder builder,
  OrdersRecord order,
) async {
  await builder.writeLine('DELIVERY DETAILS', bold: true);
  final customerName = order.clientName.trim().isNotEmpty
      ? order.clientName.trim()
      : order.recipientName.trim();
  if (customerName.isNotEmpty) {
    await builder.writeLine('Customer: $customerName');
  }
  if (order.recipientName.trim().isNotEmpty &&
      order.recipientName.trim() != customerName) {
    await builder.writeLine('Recipient: ${order.recipientName.trim()}');
  }
  final phone = orderRecipientPhone(order);
  if (phone.isNotEmpty) {
    await builder.writeLine('Phone: $phone');
  }
  final deliveryAddress = formatOrderDeliveryAddress(order);
  if (deliveryAddress.isNotEmpty) {
    await builder.writeLine('Address:');
    await builder.writeWrapped(deliveryAddress);
  }
  if (order.deliveryDate != null) {
    await builder.writeLine(
      'Delivery: ${dateTimeFormat('yyyy-MM-dd', order.deliveryDate)}',
    );
  }
  if (order.deliveryTimeSlot.isNotEmpty) {
    await builder.writeLine('Slot: ${order.deliveryTimeSlot}');
  }
  if (order.cardMessage.isNotEmpty) {
    await builder.writeLine('Card message:');
    await builder.writeWrapped(order.cardMessage);
  }
}

Future<void> _writeEscPosSignatureBlock(EscPosReceiptBuilder builder) async {
  final line = '-' * thermalPaperLineWidth();
  await builder.blankLine();
  await builder.divider();
  await builder.writeLine('Driver signature:', bold: true);
  await builder.blankLine();
  await builder.blankLine();
  await builder.writeLine(line);
  await builder.blankLine();
  await builder.writeLine('Customer signature:', bold: true);
  await builder.blankLine();
  await builder.blankLine();
  await builder.writeLine(line);
}

Future<List<int>> buildEscPosReceiptBytes({
  required OrdersRecord order,
  required List<OrderItemRecord> items,
  CompaniesRecord? company,
  String? cashierName,
  EscPosReceiptFormat format = EscPosReceiptFormat.receipt,
  String? deliveryIdOverride,
}) async {
  final isDeliverySlip = format == EscPosReceiptFormat.deliverySlip;
  final builder = EscPosReceiptBuilder()..init();

  final logoRaster = await buildCompanyLogoRaster(company);
  if (logoRaster != null) {
    await builder.appendLogoRaster(logoRaster);
  }

  final companyName = company?.companyName.trim().isNotEmpty == true
      ? company!.companyName.trim()
      : kDefaultCompanyDisplayName;
  await builder.writeLine(companyName, center: true, bold: true);

  if (company != null && company.companyUen.isNotEmpty) {
    await builder.writeLine('UEN: ${company.companyUen}', center: true);
  }
  if (company != null && company.companyAddress.isNotEmpty) {
    await builder.writeWrapped(company.companyAddress, center: true);
  }
  if (company != null && company.companyPhone.isNotEmpty) {
    await builder.writeLine('Tel: ${company.companyPhone}', center: true);
  }

  await builder.divider();

  final isDelivery = order.orderType.toLowerCase().contains('delivery');
  final title = isDeliverySlip
      ? 'DELIVERY ORDER'
      : (isDelivery ? 'DELIVERY RECEIPT' : 'SALES RECEIPT');
  await builder.writeLine(title, center: true, bold: true);
  await builder.blankLine();

  if (order.orderId.isNotEmpty) {
    await builder.writeLine('Order: ${order.orderId}');
  }
  final deliveryId = deliveryIdOverride?.trim();
  if (deliveryId != null && deliveryId.isNotEmpty) {
    await builder.writeLine('Delivery ID: $deliveryId');
  }
  if (order.createdTime != null) {
    await builder.writeLine(
      'Date: ${dateTimeFormat('yyyy-MM-dd HH:mm', order.createdTime)}',
    );
  }
  if (!isDeliverySlip) {
    await builder.writeLine(
      'Payment: ${formatPaymentMethodLabel(order.paymentType)}',
    );
  }
  await builder.writeLine(formatReceiptCashierLine(cashierName));

  await builder.divider();

  if (isDeliverySlip || isDelivery) {
    await _writeEscPosDeliveryDetails(builder, order);
    await builder.divider();
  }

  await builder.writeLine('ITEMS', bold: true);

  var computedTotal = 0.0;
  for (final item in activeOrderItems(items)) {
    final name = item.name.isNotEmpty ? item.name : 'Item';
    final qty = item.qty;
    final unitPrice = item.price;
    final lineTotal =
        item.subtotal > 0 ? item.subtotal : unitPrice * qty;
    computedTotal += lineTotal;

    await builder.writeWrapped(name);
    if (isDeliverySlip) {
      await builder.writeLine('Qty: $qty');
    } else {
      await builder.writeLine(
        escPosTwoColumn(
          'Qty $qty x ${_money(unitPrice)}',
          _money(lineTotal),
        ),
      );
    }
    final remark = ReceiptOrderItemRow.displayRemark(item.remark);
    if (remark.isNotEmpty) {
      await builder.writeLine('Remark:');
      await builder.writeWrapped(remark);
    }
    await builder.blankLine();
  }

  if (!isDeliverySlip) {
    await builder.divider();

    final itemSubtotal = computedTotal;
    final discount = order.discount;
    final total = order.total > 0
        ? order.total
        : (order.totalAmount > 0 ? order.totalAmount : computedTotal);

    if (discount > 0.005) {
      await builder.writeLine(
        escPosTwoColumn('Subtotal', _money(itemSubtotal)),
      );
      final label = order.discountLabel.trim().isNotEmpty &&
              order.discountLabel.trim() != '-'
          ? order.discountLabel.trim()
          : _money(discount);
      await builder.writeLine(
        escPosTwoColumn('Discount ($label)', '-${_money(discount)}'),
      );
    }

    await builder.writeLine(
      escPosTwoColumn('TOTAL', _money(total)),
      bold: true,
    );

    final amountPaid = readOrderAmountPaid(order);
    final balanceDue = order.balanceDue > 0
        ? order.balanceDue
        : calculateBalanceDue(saleTotal: total, amountPaid: amountPaid);
    if (amountPaid > 0.005) {
      await builder.writeLine(
        escPosTwoColumn('Amount paid', _money(amountPaid)),
      );
    }
    if (balanceDue > 0.005) {
      await builder.writeLine(
        escPosTwoColumn('Balance due', _money(balanceDue)),
        bold: true,
      );
    }
    if (order.paymentType == 'Cash' && order.cashChange > 0.005) {
      await builder.writeLine(
        escPosTwoColumn('Change', _money(order.cashChange)),
      );
    }

    await builder.blankLine();
    await builder.divider();
    await builder.writeLine('Thank you for your purchase', center: true);
    await builder.blankLine();
  } else {
    await builder.divider();
    await _writeEscPosSignatureBlock(builder);
    await builder.blankLine();
    await builder.writeLine(
      'Delivery order for fulfilment.',
      center: true,
    );
    await builder.blankLine();
  }

  final bytes = builder.build();
  bytes.addAll([0x1D, 0x56, 0x00]);
  return bytes;
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';
