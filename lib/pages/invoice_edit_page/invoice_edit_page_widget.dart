import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/create_order_service.dart';
import '/backend/customer_invoice_helpers.dart';
import '/backend/invoice_list_helpers.dart';
import '/backend/schema/invoices_record.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class InvoiceEditPageWidget extends StatefulWidget {
  const InvoiceEditPageWidget({
    super.key,
    required this.invoiceId,
  });

  final String invoiceId;

  static Future<bool?> show(
    BuildContext context, {
    required String invoiceId,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => InvoiceEditPageWidget(invoiceId: invoiceId),
      ),
    );
  }

  @override
  State<InvoiceEditPageWidget> createState() => _InvoiceEditPageWidgetState();
}

class _InvoiceEditPageWidgetState extends State<InvoiceEditPageWidget> {
  InvoicesRecord? _invoice;
  List<CustomerInvoiceLineItem> _lines = const [];
  CustomerInvoiceDiscountType _discountType = CustomerInvoiceDiscountType.amount;
  final _discountController = TextEditingController(text: '0');
  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, TextEditingController> _priceControllers = {};
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  DocumentReference get _invoiceRef =>
      InvoicesRecord.collection.doc(widget.invoiceId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final invoice = await InvoicesRecord.getDocumentOnce(_invoiceRef);
      if (invoice.status == InvoiceStatus.voided) {
        throw InvoiceWriteException('Voided invoices cannot be edited.');
      }
      final contextData = await loadInvoicePrintContext(invoice);
      final discount = parseInvoiceDiscountInput(invoice);
      _disposeLineControllers();
      _lines = contextData.lines;
      _initLineControllers();
      _discountType = discount.type;
      _discountController.text = discount.value.toStringAsFixed(
        discount.type == CustomerInvoiceDiscountType.percent ? 0 : 2,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _invoice = invoice;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = error is InvoiceWriteException
              ? error.message
              : describeFirestoreError(error);
        });
      }
    }
  }

  void _initLineControllers() {
    for (var i = 0; i < _lines.length; i++) {
      _qtyControllers[i] = TextEditingController(text: '${_lines[i].qty}');
      _priceControllers[i] = TextEditingController(
        text: _lines[i].unitPrice.toStringAsFixed(2),
      );
    }
  }

  void _disposeLineControllers() {
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    _qtyControllers.clear();
    _priceControllers.clear();
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

  Future<void> _save() async {
    final invoice = _invoice;
    if (invoice == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    for (var i = 0; i < _lines.length; i++) {
      _syncLineFromControllers(i);
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No line items for invoice.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await updateCustomerInvoice(
        invoice: invoice,
        lines: _lines,
        totals: _totals,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is InvoiceWriteException
                  ? error.message
                  : 'Failed to save invoice: ${describeFirestoreError(error)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _disposeLineControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final invoice = _invoice;
    final totals = _totals;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'Edit Invoice',
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: const [HomeNavIconButton()],
        centerTitle: true,
      ),
      body: _buildBody(theme, invoice, totals),
    );
  }

  Widget _buildBody(
    FlutterFlowTheme theme,
    InvoicesRecord? invoice,
    CustomerInvoiceTotals totals,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (invoice == null) {
      return const Center(child: Text('Invoice not found'));
    }

    return Column(
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
                        invoice.invoiceNumber,
                        style: theme.titleLarge.override(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.customerName,
                        style: theme.bodyMedium.override(
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Items',
                style: theme.titleMedium.override(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(theme.alternate),
                  columns: const [
                    DataColumn(label: Text('Order')),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Unit price')),
                    DataColumn(label: Text('Subtotal')),
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
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Discount',
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
                          hintText:
                              _discountType == CustomerInvoiceDiscountType.percent
                                  ? 'e.g. 10'
                                  : 'e.g. 25.00',
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
                      _totalRow(theme, 'Subtotal', _money(totals.subtotal)),
                      const SizedBox(height: 8),
                      _totalRow(
                        theme,
                        'Discount (${totals.discountLabel})',
                        totals.discount > 0
                            ? '-${_money(totals.discount)}'
                            : _money(0),
                      ),
                      const Divider(height: 24),
                      _totalRow(
                        theme,
                        'Total',
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
            child: FFButtonWidget(
              onPressed: _saving ? null : _save,
              text: _saving ? 'Saving…' : 'Save changes',
              icon: const Icon(Icons.save, color: Colors.white),
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
          ),
        ),
      ],
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
