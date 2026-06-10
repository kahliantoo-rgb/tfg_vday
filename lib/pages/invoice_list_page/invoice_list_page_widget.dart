import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/invoice_list_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/backend/schema/invoices_record.dart';
import '/backend/tenant_query_helpers.dart';
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
  bool _loading = true;
  bool _busy = false;
  String? _error;
  final Set<String> _selectedInvoicePaths = {};

  bool get _canManage =>
      canManageCreditAndInvoices(currentViewerRole());

  bool get _canView =>
      canViewCreditAndInvoices(currentViewerRole());

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
      final invoices = await queryTenantInvoicesRecordOnce(
        queryBuilder: (query) => query.orderBy('created_time', descending: true),
        limit: 500,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _allInvoices = invoices;
        _loading = false;
        _selectedInvoicePaths.removeWhere(
          (path) => !invoices.any((invoice) => invoice.reference.path == path),
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InvoiceListFilters get _filters => InvoiceListFilters(
        invoiceNumberQuery: _model.invoiceNumberController?.text ?? '',
        customerQuery: _model.customerController?.text ?? '',
        month: _model.selectedMonth,
        creditTerm: _model.selectedCreditTerm,
        includeVoided: _model.includeVoided,
      );

  List<InvoicesRecord> get _filteredInvoices =>
      filterInvoiceList(_allInvoices, _filters);

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
        title: const Text('Delete invoices?'),
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
            child: const Text('Delete'),
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
          const SnackBar(content: Text('Invoice(s) deleted.')),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as paid?'),
        content: Text(
          'Mark ${pending.length} invoice(s) as paid and update linked '
          'orders to payment done?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Mark paid'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await markInvoicesPaid(
        pending.map((invoice) => invoice.reference).toList(),
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
                  decoration: const InputDecoration(
                    labelText: 'Customer',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
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
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.bodyLarge.override(color: theme.error),
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
                    child: _canManage
                        ? CheckboxListTile(
                            value: selected,
                            onChanged: _busy
                                ? null
                                : (checked) =>
                                    _toggleSelection(invoice, checked),
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              invoice.invoiceNumber,
                              style: theme.titleMedium.override(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: _invoiceSubtitle(context, invoice),
                            secondary: _statusChip(invoice, theme),
                            isThreeLine: true,
                          )
                        : ListTile(
                            title: Text(
                              invoice.invoiceNumber,
                              style: theme.titleMedium.override(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: _invoiceSubtitle(context, invoice),
                            trailing: _statusChip(invoice, theme),
                            isThreeLine: true,
                          ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _canManage
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: FFButtonWidget(
                        onPressed: _busy || _selectedInvoices.isEmpty
                            ? null
                            : _confirmVoidSelected,
                        text: 'Delete',
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
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
                    const SizedBox(width: 12),
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
