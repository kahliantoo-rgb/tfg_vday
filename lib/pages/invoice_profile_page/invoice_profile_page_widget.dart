import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/record_edit_permissions.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/company_query_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/customer_invoice_helpers.dart';
import '/backend/invoice_list_helpers.dart';
import '/backend/invoice_status_display.dart';
import '/backend/payment_method_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/backend/schema/invoices_record.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/pages/invoice_edit_page/invoice_edit_page_widget.dart';
import '/components/home_nav_button.dart';
import '/components/invoice_payment_proof_section.dart';
import '/custom_code/customer_invoice_pdf_printer.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class InvoiceProfilePageWidget extends StatefulWidget {
  const InvoiceProfilePageWidget({
    super.key,
    required this.invoiceId,
  });

  final String invoiceId;

  static String routeName = 'InvoiceProfilePage';
  static String routePath = '/invoice/:invoiceId';

  static String locationForId(String invoiceId) => '/invoice/$invoiceId';

  @override
  State<InvoiceProfilePageWidget> createState() =>
      _InvoiceProfilePageWidgetState();
}

class _InvoiceProfilePageWidgetState extends State<InvoiceProfilePageWidget> {
  InvoicesRecord? _invoice;
  InvoicePrintContext? _printContext;
  bool _loading = true;
  bool _printing = false;
  String? _loadError;

  DocumentReference get _invoiceRef =>
      InvoicesRecord.collection.doc(widget.invoiceId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAndLoad());
  }

  Future<void> _bootstrapAndLoad() async {
    if (loggedIn) {
      final profile = await resolveCurrentUserProfile();
      await TenantContext.instance.initialize(profile);
    }
    await _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    if (!canViewCreditAndInvoices(currentViewerRole())) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = '__no_permission__';
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final invoice = await InvoicesRecord.getDocumentOnce(_invoiceRef);
      final printContext = await loadInvoicePrintContext(invoice);
      if (!mounted) {
        return;
      }
      setState(() {
        _invoice = invoice;
        _printContext = printContext;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = describeFirestoreError(error);
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return DateFormat('d MMM yyyy').format(date);
  }

  String _money(double value) => formatCashMoney(value);

  Future<void> _openEdit() async {
    final updated = await InvoiceEditPageWidget.show(
      context,
      invoiceId: widget.invoiceId,
    );
    if (!mounted || updated != true) {
      return;
    }
    await _loadInvoice();
  }

  Future<void> _reprint({required bool printPdf}) async {
    final contextData = _printContext;
    if (contextData == null) {
      return;
    }
    setState(() => _printing = true);
    try {
      final company =
          await resolveCustomerInvoiceCompany(contextData.customer);
      if (!mounted) {
        return;
      }
      if (printPdf) {
        await CustomerInvoicePdfPrinter.printInvoicePdf(
          context: context,
          invoiceNumber: contextData.invoice.invoiceNumber,
          customer: contextData.customer,
          lines: contextData.lines,
          totals: contextData.totals,
          company: company,
          invoiceDate: contextData.invoice.createdTime,
        );
      } else {
        await CustomerInvoicePdfPrinter.shareInvoicePdf(
          context: context,
          invoiceNumber: contextData.invoice.invoiceNumber,
          customer: contextData.customer,
          lines: contextData.lines,
          totals: contextData.totals,
          company: company,
          invoiceDate: contextData.invoice.createdTime,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _printing = false);
      }
    }
  }

  Color _statusColor(String status, FlutterFlowTheme theme) {
    switch (status) {
      case InvoiceStatus.paid:
        return theme.success;
      case InvoiceStatus.voided:
        return theme.secondaryText;
      default:
        return theme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          onPressed: () => context.pop(),
        ),
        title: Text(
          tr(context, 'invoice.profile.title'),
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: const [AppBarLanguageHomeActions()],
        centerTitle: true,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(FlutterFlowTheme theme) {
    if (widget.invoiceId.isEmpty) {
      return Center(child: Text(tr(context, 'invoice.profile.notFound')));
    }
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
              Text(
                _loadError == '__no_permission__'
                    ? tr(context, 'invoice.profile.noPermission')
                    : tr(context, 'invoice.profile.loadError'),
                style: theme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_loadError != '__no_permission__') ...[
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  style: theme.bodyMedium.override(color: theme.secondaryText),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              if (_loadError != '__no_permission__')
                FilledButton(
                  onPressed: _bootstrapAndLoad,
                  child: Text(tr(context, 'common.retry')),
                ),
            ],
          ),
        ),
      );
    }

    final invoice = _invoice;
    final printContext = _printContext;
    if (invoice == null || printContext == null) {
      return Center(child: Text(tr(context, 'invoice.profile.notFound')));
    }

    final customer = printContext.customer;
    final lines = printContext.lines;
    final totals = printContext.totals;
    final canEdit = canEditInvoiceRecord(currentViewerRole(), invoice);

    return RefreshIndicator(
      onRefresh: _loadInvoice,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice.invoiceNumber,
                          style: theme.headlineSmall.override(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          invoiceStatusDisplayLabel(context, invoice.status),
                        ),
                        backgroundColor: _statusColor(invoice.status, theme)
                            .withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: _statusColor(invoice.status, theme),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(context, 'invoice.profile.dateLine',
                        params: {'date': _formatDate(invoice.createdTime)}),
                  ),
                  if (invoice.paidAt != null)
                    Text(
                      tr(context, 'invoice.profile.paidLine',
                          params: {'date': _formatDate(invoice.paidAt)}),
                    ),
                  if (invoice.creditTerm.isNotEmpty)
                    Text(
                      tr(context, 'invoice.profile.creditTermLine', params: {
                        'term': creditTermShortLabel(invoice.creditTerm),
                      }),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          InvoicePaymentProofSection(invoice: invoice),
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
                  Text(customer.name.isNotEmpty ? customer.name : invoice.customerName),
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
                  if (invoice.hasCustomerRef()) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          openInvoiceCustomerProfile(context, invoice),
                      icon: const Icon(Icons.person_outline),
                      label: Text(tr(context, 'invoice.profile.openCustomer')),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'invoice.label.items'),
            style: theme.titleLarge.override(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                invoice.orderIds.isEmpty
                    ? tr(context, 'invoice.profile.noLineItems')
                    : tr(context, 'invoice.profile.ordersLine',
                        params: {'orders': invoice.orderIds.join(', ')}),
                style: theme.bodyMedium.override(color: theme.secondaryText),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(theme.alternate),
                columns: [
                  DataColumn(
                      label: Text(tr(context, 'invoice.column.order'))),
                  DataColumn(
                      label: Text(tr(context, 'invoice.column.product'))),
                  DataColumn(label: Text(tr(context, 'invoice.column.qty'))),
                  DataColumn(
                      label: Text(tr(context, 'invoice.column.unitPrice'))),
                  DataColumn(
                      label: Text(tr(context, 'invoice.column.subtotal'))),
                ],
                rows: [
                  for (final line in lines)
                    DataRow(
                      cells: [
                        DataCell(Text(line.orderId)),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(line.productName),
                              if (line.remark.isNotEmpty)
                                Text(
                                  line.remark,
                                  style: theme.bodySmall.override(
                                    color: theme.secondaryText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        DataCell(Text('${line.qty}')),
                        DataCell(Text(_money(line.unitPrice))),
                        DataCell(Text(_money(line.lineSubtotal))),
                      ],
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _totalRow(
                      theme, tr(context, 'invoice.label.subtotal'), _money(totals.subtotal)),
                  const SizedBox(height: 8),
                  _totalRow(
                    theme,
                    tr(context, 'invoice.profile.discountLine',
                        params: {'label': totals.discountLabel}),
                    totals.discount > 0
                        ? '-${_money(totals.discount)}'
                        : _money(0),
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
          const SizedBox(height: 16),
          if (canEdit)
            FFButtonWidget(
              onPressed: _openEdit,
              text: tr(context, 'invoice.profile.editInvoice'),
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              options: FFButtonOptions(
                width: double.infinity,
                height: 48,
                color: theme.tertiary,
                textStyle: theme.titleMedium.override(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          if (canEdit) const SizedBox(height: 8),
          FFButtonWidget(
            onPressed: _printing ? null : () => _reprint(printPdf: true),
            text: _printing
                ? tr(context, 'common.preparing')
                : 'Reprint invoice (PDF)',
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
            onPressed: _printing ? null : () => _reprint(printPdf: false),
            text: 'Share invoice PDF',
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
