import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/invoice_navigation_helpers.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/customer_helpers.dart';
import '/backend/invoice_list_helpers.dart';
import '/backend/invoice_payment_proof_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/backend/schema/invoices_record.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/nav/nav.dart';
import 'invoice_list_page_model.dart';
export 'invoice_list_page_model.dart';

class InvoiceListPageWidget extends StatefulWidget {
  const InvoiceListPageWidget({super.key});

  static String routeName = 'InvoiceListPage';
  static String routePath = '/invoiceListPage';

  @override
  State<InvoiceListPageWidget> createState() => _InvoiceListPageWidgetState();
}

class _InvoiceListPageWidgetState extends State<InvoiceListPageWidget> {
  late InvoiceListPageModel _model;
  List<InvoicesRecord> _allInvoices = const [];
  List<CustomersRecord> _customers = const [];
  List<CustomersRecord> _customerMatches = const [];
  String? _selectedCustomerRefPath;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  final Set<String> _selectedInvoicePaths = {};

  bool get _canView =>
      canViewCreditAndInvoices(currentViewerRole());

  bool get _canVoid => canVoidInvoices(currentViewerRole());

  bool get _canMarkPaid => canMarkInvoicesPaid(currentViewerRole());

  bool get _canManageSelection => _canVoid || _canMarkPaid;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InvoiceListPageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
        AppStateNotifier.instance.syncUserRole(profile?.role);
      }
      if (mounted) {
        setState(() {});
        await _loadInvoices();
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    if (!_canView) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'You do not have permission to view invoices.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        queryInvoicesForTenantList(limit: 500),
        queryCustomersForTenantList(limit: 500),
      ]);
      final invoices = results[0] as List<InvoicesRecord>;
      final customers = results[1] as List<CustomersRecord>;
      if (!mounted) {
        return;
      }
      setState(() {
        _allInvoices = invoices;
        _customers = customers;
        _loading = false;
        _selectedInvoicePaths.removeWhere(
          (path) => !invoices.any((invoice) => invoice.reference.path == path),
        );
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = describeFirestoreError(error);
        });
      }
    }
  }

  InvoiceListFilters get _filters => InvoiceListFilters(
        invoiceNumberQuery: _model.invoiceNumberController?.text ?? '',
        customerQuery: _model.customerController?.text ?? '',
        selectedCustomerRefPath: _selectedCustomerRefPath,
        month: _model.selectedMonth,
        creditTerm: _model.selectedCreditTerm,
        includeVoided: _model.includeVoided,
      );

  Map<String, CustomersRecord> get _customersByRefPath =>
      buildCustomersByRefPath(_customers);

  List<InvoicesRecord> get _filteredInvoices => filterInvoiceList(
        _allInvoices,
        _filters,
        customersByRefPath: _customersByRefPath,
      );

  void _onCustomerSearchChanged(String value) {
    setState(() {
      _selectedCustomerRefPath = null;
      _customerMatches = filterCustomersForInvoiceSearch(_customers, value);
    });
  }

  void _onCustomerSelected(CustomersRecord customer) {
    setState(() {
      _selectedCustomerRefPath = customer.reference.path;
      _model.customerController?.text = customer.customerId.isNotEmpty
          ? '${customer.customerId} · ${customer.name}'
          : customer.name;
      _customerMatches = const [];
    });
  }

  void _clearCustomerSearch() {
    setState(() {
      _selectedCustomerRefPath = null;
      _model.customerController?.clear();
      _customerMatches = const [];
    });
  }

  List<String> get _creditTermOptions =>
      collectInvoiceCreditTerms(_allInvoices);

  List<DateTime> get _monthOptions {
    final now = DateTime.now();
    return List.generate(24, (index) {
      return DateTime(now.year, now.month - index, 1);
    });
  }

  List<InvoicesRecord> get _selectedInvoices => _filteredInvoices
      .where((invoice) => _selectedInvoicePaths.contains(invoice.reference.path))
      .toList();

  void _toggleSelection(InvoicesRecord invoice, bool? selected) {
    setState(() {
      final path = invoice.reference.path;
      if (selected == true) {
        _selectedInvoicePaths.add(path);
      } else {
        _selectedInvoicePaths.remove(path);
      }
    });
  }

  Future<void> _confirmVoidSelected() async {
    if (_selectedInvoices.isEmpty) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Void invoices?'),
        content: Text(
          'Void ${_selectedInvoices.length} invoice(s)? '
          'Linked orders can be invoiced again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await voidInvoices(
        _selectedInvoices.map((invoice) => invoice.reference).toList(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _selectedInvoicePaths.clear());
      await _loadInvoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice(s) voided.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _markSelectedPaid() async {
    final pending = _selectedInvoices
        .where((invoice) => invoice.status == InvoiceStatus.pending)
        .toList();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select pending invoice(s) to mark paid.')),
      );
      return;
    }

    final result = await showMarkInvoicesPaidDialog(
      context,
      invoiceCount: pending.length,
      storageInvoiceId: pending.first.reference.id,
    );
    if (result == null || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await markInvoicesPaid(
        pending.map((invoice) => invoice.reference).toList(),
        paymentProofUrl: result.paymentProofUrl,
      );
      if (!mounted) {
        return;
      }
      setState(() => _selectedInvoicePaths.clear());
      await _loadInvoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice(s) marked paid.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return DateFormat('d MMM yyyy').format(date);
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
    final filtered = _filteredInvoices;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primary,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Invoice List',
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: const [HomeNavIconButton()],
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _model.invoiceNumberController,
                  focusNode: _model.invoiceNumberFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Invoice number',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _model.customerController,
                  focusNode: _model.customerFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Customer',
                    hintText: 'Search customer name or ID (e.g. TFG01)',
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: (_model.customerController?.text.isNotEmpty ?? false)
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: _clearCustomerSearch,
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _onCustomerSearchChanged,
                ),
                if (_customerMatches.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.alternate),
                    ),
                    child: Column(
                      children: [
                        for (final customer in _customerMatches)
                          ListTile(
                            dense: true,
                            title: Text(customer.name),
                            subtitle: Text(
                              [
                                if (customer.customerId.isNotEmpty)
                                  customer.customerId,
                                if (customer.phone.isNotEmpty) customer.phone,
                              ].join(' · '),
                            ),
                            onTap: () => _onCustomerSelected(customer),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<DateTime?>(
                        value: _model.selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<DateTime?>(
                            value: null,
                            child: Text('All months'),
                          ),
                          ..._monthOptions.map(
                            (month) => DropdownMenuItem<DateTime?>(
                              value: month,
                              child: Text(DateFormat('MMM yyyy').format(month)),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _model.selectedMonth = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _model.selectedCreditTerm.isEmpty
                            ? ''
                            : _model.selectedCreditTerm,
                        decoration: const InputDecoration(
                          labelText: 'Credit term',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('All terms'),
                          ),
                          ..._creditTermOptions.map(
                            (term) => DropdownMenuItem<String>(
                              value: term,
                              child: Text(creditTermShortLabel(term)),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => _model.selectedCreditTerm = value ?? '',
                        ),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show voided'),
                  value: _model.includeVoided,
                  onChanged: (value) =>
                      setState(() => _model.includeVoided = value),
                ),
              ],
            ),
          ),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Could not load invoices.',
                        style: theme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.override(
                          color: theme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadInvoices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No invoices found.',
                  style: theme.bodyLarge.override(color: theme.secondaryText),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final invoice = filtered[index];
                  final selected =
                      _selectedInvoicePaths.contains(invoice.reference.path);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: _canManageSelection
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: selected,
                                onChanged: _busy
                                    ? null
                                    : (checked) =>
                                        _toggleSelection(invoice, checked),
                              ),
                              Expanded(
                                child: ListTile(
                                  onTap: () => openInvoiceProfile(
                                    context,
                                    invoice.reference,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          invoice.invoiceNumber,
                                          style: theme.titleMedium.override(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      _statusChip(invoice, theme),
                                    ],
                                  ),
                                  subtitle: _invoiceSubtitle(context, invoice),
                                  isThreeLine: true,
                                ),
                              ),
                            ],
                          )
                        : ListTile(
                            onTap: () => openInvoiceProfile(
                              context,
                              invoice.reference,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    invoice.invoiceNumber,
                                    style: theme.titleMedium.override(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                _statusChip(invoice, theme),
                              ],
                            ),
                            subtitle: _invoiceSubtitle(context, invoice),
                            isThreeLine: true,
                          ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _canManageSelection
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_canVoid)
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: _busy || _selectedInvoices.isEmpty
                              ? null
                              : _confirmVoidSelected,
                          text: 'Void',
                          icon: const Icon(Icons.block, color: Colors.white),
                          options: FFButtonOptions(
                            height: 48,
                            color: theme.error,
                            textStyle: theme.titleSmall.override(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    if (_canVoid && _canMarkPaid) const SizedBox(width: 12),
                    if (_canMarkPaid)
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: _busy || _selectedInvoices.isEmpty
                              ? null
                              : _markSelectedPaid,
                          text: 'Mark paid',
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                          options: FFButtonOptions(
                            height: 48,
                            color: theme.success,
                            textStyle: theme.titleSmall.override(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _invoiceSubtitle(BuildContext context, InvoicesRecord invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(invoice.customerName),
        if (invoice.creditTerm.isNotEmpty)
          Text(creditTermShortLabel(invoice.creditTerm)),
        Text(
          '${_formatDate(invoice.createdTime)} · '
          '${formatCashMoney(invoice.total)} · '
          '${invoice.orderIds.length} order(s)',
        ),
      ],
    );
  }

  Widget _statusChip(InvoicesRecord invoice, FlutterFlowTheme theme) {
    return Chip(
      label: Text(invoiceStatusLabel(invoice.status)),
      backgroundColor: _statusColor(invoice.status, theme).withValues(
        alpha: 0.15,
      ),
      labelStyle: TextStyle(
        color: _statusColor(invoice.status, theme),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
