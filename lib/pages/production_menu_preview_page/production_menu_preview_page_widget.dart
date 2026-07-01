import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/material_usage_report_service.dart';
import '/backend/order_production_menu_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/custom_code/bluetooth_receipt_printer.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'production_menu_preview_page_model.dart';
export 'production_menu_preview_page_model.dart';

class ProductionMenuPreviewPageWidget extends StatefulWidget {
  const ProductionMenuPreviewPageWidget({
    super.key,
    required this.orderRef,
  });

  final DocumentReference? orderRef;

  static String routeName = 'ProductionMenuPreviewPage';
  static String routePath = '/productionMenuPreviewPage';

  @override
  State<ProductionMenuPreviewPageWidget> createState() =>
      _ProductionMenuPreviewPageWidgetState();
}

class _ProductionMenuPreviewPageWidgetState
    extends State<ProductionMenuPreviewPageWidget> {
  late ProductionMenuPreviewPageModel _model;
  OrderProductionMenu? _menu;
  bool _loading = true;
  bool _printing = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductionMenuPreviewPageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final orderRef = widget.orderRef;
    if (orderRef == null) {
      setState(() {
        _error = tr(context, 'order.production.notFound');
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      final menu = await buildOrderProductionMenu(orderRef);
      if (!mounted) {
        return;
      }
      setState(() {
        _menu = menu;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = describeFirestoreError(error);
        _loading = false;
      });
    }
  }

  Future<void> _printThermal() async {
    final menu = _menu;
    if (menu == null || _printing) {
      return;
    }
    if (!BluetoothReceiptPrinter.isBluetoothPrintAvailable) {
      if (mounted) {
        BluetoothReceiptPrinter.showSnack(
          context,
          BluetoothReceiptPrinter.unsupportedPlatformMessage(),
        );
      }
      return;
    }
    setState(() => _printing = true);
    try {
      await BluetoothReceiptPrinter.printProductionMenu(
        context,
        menu: menu,
      );
    } finally {
      if (mounted) {
        setState(() => _printing = false);
      }
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackground,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText),
          onPressed: () => context.safePop(),
        ),
        title: Text(
          tr(context, 'order.production.title'),
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            fontSize: 22,
          ),
        ),
        actions: [
          if (_menu != null) ...[
            FlutterFlowIconButton(
              borderRadius: 30,
              buttonSize: 60,
              icon: Icon(Icons.bluetooth, color: theme.primaryText),
              onPressed: () =>
                  BluetoothReceiptPrinter.openPrinterSettings(context),
            ),
            IconButton(
              icon: _printing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print),
              tooltip: 'Print thermal',
              onPressed: _printing ? null : _printThermal,
            ),
          ],
          const HomeNavIconButton(),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _buildContent(context, theme),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FlutterFlowTheme theme) {
    final menu = _menu!;
    final order = menu.order;
    final date = order.createdTime ?? order.deliveryDate;
    final dateLabel = date != null
        ? DateFormat('d MMM yyyy, HH:mm').format(date.toLocal())
        : '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.alternate),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'order.production.sheetTitle'),
                      style: theme.titleLarge.override(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(context, 'order.production.sheetHint'),
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                      ),
                    ),
                    const Divider(height: 24),
                    _infoRow(
                      context,
                      theme,
                      tr(context, 'order.production.orderLabel'),
                      productionMenuOrderLabel(order),
                    ),
                    _infoRow(
                      context,
                      theme,
                      tr(context, 'order.production.dateLabel'),
                      dateLabel,
                    ),
                    if (order.clientName.isNotEmpty)
                      _infoRow(
                        context,
                        theme,
                        tr(context, 'order.production.customerLabel'),
                        order.clientName,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr(context, 'order.production.productsInOrder'),
                style: theme.titleMedium.override(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (menu.orderItems.isEmpty)
                Text(
                  tr(context, 'order.production.noLineItems'),
                  style: theme.bodyMedium.override(color: theme.secondaryText),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.alternate),
                  ),
                  child: Column(
                    children: [
                      for (final item in menu.orderItems)
                        ListTile(
                          title: Text(item.name),
                          trailing: Text('${item.qty}'),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                tr(context, 'order.production.materialsRequired'),
                style: theme.titleMedium.override(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (menu.materials.isEmpty)
                Text(
                  tr(context, 'order.production.noRecipeMaterials'),
                  style: theme.bodyMedium.override(color: theme.secondaryText),
                )
              else
                _materialsTable(context, theme, menu),
              if (menu.unmatchedProducts.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  tr(context, 'order.production.noRecipeLinked'),
                  style: theme.titleMedium.override(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.alternate),
                  ),
                  child: Column(
                    children: [
                      for (final row in menu.unmatchedProducts)
                        ListTile(
                          title: Text(row.productName),
                          trailing: Text(
                            tr(context, 'report.materialUsage.soldCount',
                                params: {'count': '${row.totalQty}'}),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (kIsWeb &&
                  !BluetoothReceiptPrinter.isBluetoothPrintAvailable) ...[
                const SizedBox(height: 16),
                Text(
                  'Web printing needs Chrome or Edge on HTTPS, and a BLE '
                  'thermal printer. Tap the Bluetooth icon above to pair.',
                  style: theme.bodySmall.override(color: theme.secondaryText),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _printing ? null : _printThermal,
                icon: _printing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.print),
                label: const Text('Print thermal'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    FlutterFlowTheme theme,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.bodyMedium.override(color: theme.secondaryText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.bodyMedium.override(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _materialsTable(
    BuildContext context,
    FlutterFlowTheme theme,
    OrderProductionMenu menu,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    tr(context, 'order.production.materialCol'),
                    style: theme.labelMedium.override(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    tr(context, 'common.qty'),
                    textAlign: TextAlign.end,
                    style: theme.labelMedium.override(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    tr(context, 'order.production.costCol'),
                    textAlign: TextAlign.end,
                    style: theme.labelMedium.override(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final row in menu.materials)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.materialName),
                        if (row.unit.isNotEmpty)
                          Text(
                            row.unit,
                            style: theme.bodySmall.override(
                              color: theme.secondaryText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatMaterialUsageQty(row.totalQty),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (row.unitCost > 0)
                          Text(
                            formatCashMoney(row.unitCost),
                            style: theme.bodySmall.override(
                              color: theme.secondaryText,
                            ),
                          ),
                        Text(
                          row.lineCost > 0
                              ? formatCashMoney(row.lineCost)
                              : '-',
                          textAlign: TextAlign.end,
                          style: theme.bodyMedium.override(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (menu.totalMaterialCost > 0) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(context, 'order.production.totalMaterialCost'),
                      style: theme.titleSmall.override(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatCashMoney(menu.totalMaterialCost),
                    style: theme.titleMedium.override(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
