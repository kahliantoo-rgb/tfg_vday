import '/app_branding.dart';
import '/backend/material_usage_report_service.dart';
import '/backend/order_production_menu_helpers.dart';
import '/backend/schema/companies_record.dart';
import '/components/receipt_order_item_list.dart';
import '/custom_code/esc_pos_receipt_builder.dart';
import '/custom_code/esc_pos_text_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

Future<List<int>> buildEscPosProductionMenuBytes({
  required OrderProductionMenu menu,
  CompaniesRecord? company,
}) async {
  final order = menu.order;
  final builder = EscPosReceiptBuilder()..init();

  final logoRaster = await buildCompanyLogoRaster(company);
  if (logoRaster != null) {
    await builder.appendLogoRaster(logoRaster);
  }

  final companyName = company?.companyName.trim().isNotEmpty == true
      ? company!.companyName.trim()
      : kDefaultCompanyDisplayName;
  await builder.writeLine(companyName, center: true, bold: true);
  await builder.divider();

  await builder.writeLine('PRODUCTION MENU', center: true, bold: true);
  await builder.writeLine(
    'Shop floor — not customer receipt',
    center: true,
  );
  await builder.blankLine();

  final orderLabel = productionMenuOrderLabel(order);
  await builder.writeLine('Order: $orderLabel', bold: true);

  if (order.createdTime != null) {
    await builder.writeLine(
      'Order date: ${dateTimeFormat('yyyy-MM-dd HH:mm', order.createdTime)}',
    );
  }
  if (order.deliveryDate != null) {
    await builder.writeLine(
      'Delivery date: ${dateTimeFormat('yyyy-MM-dd', order.deliveryDate)}',
    );
  }
  if (order.deliveryTimeSlot.isNotEmpty) {
    await builder.writeLine('Time slot: ${order.deliveryTimeSlot}');
  }
  if (order.orderType.isNotEmpty) {
    await builder.writeLine('Type: ${order.orderType}');
  }
  if (order.clientName.trim().isNotEmpty) {
    await builder.writeLine('Customer: ${order.clientName.trim()}');
  }
  if (order.recipientName.trim().isNotEmpty &&
      order.recipientName.trim() != order.clientName.trim()) {
    await builder.writeLine('Recipient: ${order.recipientName.trim()}');
  }

  await builder.divider();
  await builder.writeLine('PRODUCTS', bold: true);

  if (menu.orderItems.isEmpty) {
    await builder.writeLine('(No line items)');
  } else {
    for (final item in menu.orderItems) {
      final name = item.name.isNotEmpty ? item.name : 'Item';
      await builder.writeWrapped(name, center: false);
      await builder.writeLine('Qty: ${item.qty}');
      final remark = ReceiptOrderItemRow.displayRemark(item.remark);
      if (remark.isNotEmpty) {
        await builder.writeLine('Remark:');
        await builder.writeWrapped(remark);
      }
      await builder.blankLine();
    }
  }

  await builder.divider();
  await builder.writeLine('MATERIALS REQUIRED', bold: true);

  if (menu.materials.isEmpty) {
    await builder.writeLine('(No recipe materials — add recipes on products)');
  } else {
    for (final row in menu.materials) {
      final name = row.materialName.isNotEmpty ? row.materialName : 'Material';
      final qtyLabel = formatMaterialUsageQty(row.totalQty);
      final unitSuffix = row.unit.isNotEmpty ? ' ${row.unit}' : '';
      await builder.writeLine(
        escPosTwoColumn(name, '$qtyLabel$unitSuffix'),
      );
    }
  }

  if (menu.unmatchedProducts.isNotEmpty) {
    await builder.divider();
    await builder.writeLine('NO RECIPE LINKED', bold: true);
    for (final row in menu.unmatchedProducts) {
      await builder.writeLine(
        escPosTwoColumn(row.productName, '${row.totalQty} sold'),
      );
    }
  }

  await builder.blankLine();
  await builder.divider();
  await builder.writeLine(
    'Printed: ${dateTimeFormat('yyyy-MM-dd HH:mm', getCurrentTimestamp)}',
    center: true,
  );
  await builder.blankLine();

  final bytes = builder.build();
  bytes.addAll([0x1D, 0x56, 0x00]);
  return bytes;
}
