import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/company_query_helpers.dart';
import '/backend/customer_helpers.dart';
import '/backend/customer_invoice_helpers.dart';
import '/backend/invoice_list_helpers.dart';
import '/backend/order_id_service.dart';
import '/backend/payment_method_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/custom_code/customer_invoice_pdf_printer.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

/// Full-screen confirm step before creating a credit-customer invoice.
class CustomerInvoiceConfirmPageWidget extends StatefulWidget {
  const CustomerInvoiceConfirmPageWidget({
    super.key,
    required this.customer,
    required this.entries,
  });

  final CustomersRecord customer;
  final List<CustomerPurchaseEntry> entries;

  static Future<bool?> show(
    BuildContext context, {
    required CustomersRecord customer,
    required List<CustomerPurchaseEntry> entries,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CustomerInvoiceConfirmPageWidget(
          customer: customer,
          entries: entries,
        ),
      ),
    );
  }

  @override
  State<CustomerInvoiceConfirmPageWidget> createState() =>
      _CustomerInvoiceConfirmPageWidgetState();
}

class _CustomerInvoiceConfirmPageWidgetState
    extends State<CustomerInvoiceConfirmPageWidget> {
  List<CustomerInvoiceLineItem> _lines = const [];
  CustomerInvoiceDiscountType _discountType = CustomerInvoiceDiscountType.amount;
  final _discountController = TextEditingController(text: '0');
  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, TextEditingController> _priceControllers = {};
  String _previewInvoiceNumber = '…';
  bool _loadingPreview = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _lines = buildCustomerInvoiceLineItems(widget.entries);
    _initLineControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreviewNumber());
  }

  void _initLineControllers() {
    for (var i = 0; i < _lines.length; i++) {
      _qtyControllers[i] = TextEditingController(text: '${_lines[i].qty}');
      _priceControllers[i] = TextEditingController(
        text: _lines[i].unitPrice.toStringAsFixed(2),
      );
    }
  }

  Future<void> _loadPreviewNumber() async {
    final preview = await OrderIdService.previewNextInvoiceNumber();
    if (mounted) {
      setState(() {
        _previewInvoiceNumber = preview;
        _loadingPreview = false;
      });
    }
  }

  CustomerInvoiceDiscountInput get _discountInput {
    final parsed = double.tryParse(_discountController.text.trim()) ?? 0;
    return CustomerInvoiceDiscountInput(
      type: _discountType,
      value: parsed,
    );
  }

  CustomerInvoiceTotals get _totals => calculateCustomerInvoiceTotals(
        lines: _lines,
        discount: _discountInput,
      );

  void _syncLineFromControllers(int index) {
    final qty = int.tryParse(_qtyControllers[index]?.text.trim() ?? '') ?? 0;
    final price =
        double.tryParse(_priceControllers[index]?.text.trim() ?? '') ?? 0;
    setState(() {
      _lines = [
        for (var i = 0; i < _lines.length; i++)
          if (i == index)
            copyCustomerInvoiceLineItem(
              _lines[i],
              qty: qty > 0 ? qty : 1,
              unitPrice: price >= 0 ? price : 0,
            )
          else
            _lines[i],
      ];
    });
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  Future<void> _submit({required bool printPdf}) async {
    FocusScope.of(context).unfocus();
    for (var i = 0; i < _lines.length; i++) {
      _syncLineFromControllers(i);
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'invoice.snack.noLineItems'))),
      );
      return;
    }

    try {
      await assertOrdersAvailableForInvoicing(widget.entries);
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final totals = _totals;
      final invoiceNumber = await createCustomerInvoiceWithNumber(
        customer: widget.customer,
        entries: widget.entries,
        totals: totals,
      );
      final company = await resolveCustomerInvoiceCompany(widget.customer);
      if (!mounted) {
        return;
      }
      if (printPdf) {
        await CustomerInvoicePdfPrinter.printInvoicePdf(
          context: context,
          invoiceNumber: invoiceNumber,
          customer: widget.customer,
          lines: _lines,
          totals: totals,
          company: company,
        );
      } else {
        await CustomerInvoicePdfPrinter.shareInvoicePdf(
          context: context,
          invoiceNumber: invoiceNumber,
          customer: widget.customer,
          lines: _lines,
          totals: totals,
          company: company,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(context, 'invoice.snack.createFailed',
                  params: {'error': '$error'}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final totals = _totals;
    final customer = widget.customer;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
        ),
        title: Text(
          tr(context, 'invoice.confirm.title'),
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'invoice.label.invoiceNumber'),
                          style: theme.labelMedium.override(
                            color: theme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _loadingPreview
                              ? tr(context, 'common.loading')
                              : _previewInvoiceNumber,
                          style: theme.titleLarge.override(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_loadingPreview)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              tr(context, 'invoice.confirm.assignedOnConfirm'),
                              style: theme.bodySmall.override(
                                color: theme.secondaryText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'invoice.label.customer'),
                          style: theme.titleMedium.override(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(customer.name, style: theme.bodyLarge),
                        if (customer.customerId.isNotEmpty)
                          Text(
                            tr(context, 'invoice.profile.customerIdLine',
                                params: {'id': customer.customerId}),
                          ),
                        if (customer.phone.isNotEmpty)
                          Text(
                            tr(context, 'invoice.profile.phoneLine',
                                params: {'phone': customer.phone}),
                          ),
                        if (customer.email.isNotEmpty)
                          Text(
                            tr(context, 'invoice.profile.emailLine',
                                params: {'email': customer.email}),
                          ),
                        if (customer.billingAddress.isNotEmpty)
                          Text(
                            tr(context, 'invoice.profile.addressLine',
                                params: {'address': customer.billingAddress}),
                          ),
                        if (customer.creditTerm.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              tr(context, 'invoice.profile.creditTermLine',
                                  params: {
                                    'term': creditTermShortLabel(
                                      customer.creditTerm,
                                    ),
                                  }),
                              style: theme.bodyMedium.override(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr(context, 'invoice.label.items'),
                  style: theme.titleMedium.override(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.sizeOf(context).width - 32,
                    ),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        theme.alternate,
                      ),
                      columns: [
                        DataColumn(
                            label: Text(tr(context, 'invoice.column.order'))),
                        DataColumn(
                            label:
                                Text(tr(context, 'invoice.column.product'))),
                        DataColumn(
                            label: Text(tr(context, 'invoice.column.qty'))),
                        DataColumn(
                            label:
                                Text(tr(context, 'invoice.column.unitPrice'))),
                        DataColumn(
                            label:
                                Text(tr(context, 'invoice.column.subtotal'))),
                      ],
                      rows: [
                        for (var i = 0; i < _lines.length; i++)
                          DataRow(
                            cells: [
                              DataCell(Text(_lines[i].orderId)),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_lines[i].productName),
                                    if (_lines[i].remark.isNotEmpty)
                                      Text(
                                        _lines[i].remark,
                                        style: theme.bodySmall.override(
                                          color: theme.secondaryText,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 56,
                                  child: TextField(
                                    controller: _qtyControllers[i],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (_) => _syncLineFromControllers(i),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 88,
                                  child: TextField(
                                    controller: _priceControllers[i],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                    ],
                                    onChanged: (_) => _syncLineFromControllers(i),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                      prefixText: '\$',
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(_money(_lines[i].lineSubtotal))),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          tr(context, 'invoice.label.discount'),
                          style: theme.titleMedium.override(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                          selected: {_discountType},
                          onSelectionChanged: (selection) {
                            setState(() => _discountType = selection.first);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: _discountType ==
                                    CustomerInvoiceDiscountType.percent
                                ? tr(context, 'invoice.discount.hintPercent')
                                : tr(context, 'invoice.discount.hintAmount'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _totalRow(
                            theme,
                            tr(context, 'invoice.label.subtotal'),
                            _money(totals.subtotal)),
                        const SizedBox(height: 8),
                        _totalRow(
                          theme,
                          tr(context, 'invoice.profile.discountLine',
                              params: {'label': totals.discountLabel}),
                          '-${_money(totals.discount)}',
                        ),
                        const Divider(height: 24),
                        _totalRow(
                          theme,
                          tr(context, 'invoice.label.total'),
                          _money(totals.total),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FFButtonWidget(
                    onPressed: _submitting ? null : () => _submit(printPdf: true),
                    text: _submitting
                        ? tr(context, 'common.creating')
                        : 'Create & print PDF',
                    icon: const Icon(Icons.print, color: Colors.white),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48,
                      color: theme.primary,
                      textStyle: theme.titleMedium.override(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FFButtonWidget(
                    onPressed:
                        _submitting ? null : () => _submit(printPdf: false),
                    text: 'Create & share PDF',
                    icon: const Icon(Icons.share, color: Colors.white),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48,
                      color: theme.secondary,
                      textStyle: theme.titleMedium.override(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    FlutterFlowTheme theme,
    String label,
    String value, {
    bool bold = false,
  }) {
    final style = bold
        ? theme.titleMedium.override(fontWeight: FontWeight.bold)
        : theme.bodyLarge;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
