import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/company_query_helpers.dart';
import '/backend/customer_helpers.dart';
import '/backend/customer_invoice_helpers.dart';
import '/backend/invoice_list_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/customer_invoice_generate_dialog.dart';
import '/components/home_nav_button.dart';
import '/custom_code/customer_invoice_pdf_printer.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/nav/nav.dart';
import 'customer_profile_page_model.dart';
export 'customer_profile_page_model.dart';

class CustomerProfilePageWidget extends StatefulWidget {
  const CustomerProfilePageWidget({
    super.key,
    required this.customerRef,
  });

  final DocumentReference? customerRef;

  static String routeName = 'CustomerProfilePage';
  static String routePath = '/customerProfilePage';

  @override
  State<CustomerProfilePageWidget> createState() =>
      _CustomerProfilePageWidgetState();
}

class _CustomerProfilePageWidgetState extends State<CustomerProfilePageWidget> {
  late CustomerProfilePageModel _model;
  List<CustomerPurchaseEntry> _history = const [];
  bool _loadingHistory = true;
  bool _generatingInvoice = false;
  final Set<String> _selectedOrderPaths = {};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomerProfilePageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
        AppStateNotifier.instance.syncUserRole(profile?.role);
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadHistory(CustomersRecord customer) async {
    setState(() => _loadingHistory = true);
    try {
      final history = await loadCustomerPurchaseHistory(customer);
      if (!mounted) {
        return;
      }
      setState(() {
        _history = history;
        _loadingHistory = false;
        _selectedOrderPaths.removeWhere(
          (path) => !history.any((entry) => entry.order.reference.path == path),
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return DateFormat('d MMM yyyy, HH:mm').format(date);
  }

  void _toggleOrderSelection(CustomerPurchaseEntry entry, bool? selected) {
    setState(() {
      final path = entry.order.reference.path;
      if (selected == true) {
        _selectedOrderPaths.add(path);
      } else {
        _selectedOrderPaths.remove(path);
      }
    });
  }

  List<CustomerPurchaseEntry> get _selectedEntries => _history
      .where((entry) => _selectedOrderPaths.contains(entry.order.reference.path))
      .toList();

  Future<void> _generateInvoice(CustomersRecord customer) async {
    if (_selectedEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one order.')),
      );
      return;
    }
    final config = await showCustomerInvoiceGenerateDialog(context);
    if (config == null || !mounted) {
      return;
    }

    setState(() => _generatingInvoice = true);
    try {
      final unavailable = _selectedEntries
          .where((entry) => !isOrderAvailableForInvoicing(entry.order))
          .toList();
      if (unavailable.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'One or more selected orders are already on an active invoice.',
              ),
            ),
          );
        }
        return;
      }

      final lines = buildCustomerInvoiceLineItems(_selectedEntries);
      final totals = calculateCustomerInvoiceTotals(
        lines: lines,
        discount: config.discount,
      );
      final invoiceNumber = await createCustomerInvoiceWithNumber(
        customer: customer,
        entries: _selectedEntries,
        totals: totals,
      );
      final company = await getDefaultCompanyOnce();
      if (!mounted) {
        return;
      }
      if (config.printPdf) {
        await CustomerInvoicePdfPrinter.printInvoicePdf(
          context: context,
          invoiceNumber: invoiceNumber,
          customer: customer,
          lines: lines,
          totals: totals,
          company: company,
        );
      } else {
        await CustomerInvoicePdfPrinter.shareInvoicePdf(
          context: context,
          invoiceNumber: invoiceNumber,
          customer: customer,
          lines: lines,
          totals: totals,
          company: company,
        );
      }
      if (mounted) {
        setState(() {
          _selectedOrderPaths.clear();
        });
        await _loadHistory(customer);
      }
    } finally {
      if (mounted) {
        setState(() => _generatingInvoice = false);
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
    final canManageCredit =
        canManageCreditAndInvoices(currentViewerRole());
    final canViewCredit =
        canViewCreditAndInvoices(currentViewerRole());
    if (widget.customerRef == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Profile')),
        body: const Center(child: Text('Customer not found')),
      );
    }

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
          'Customer Profile',
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: const [HomeNavIconButton()],
        centerTitle: true,
      ),
      body: StreamBuilder<CustomersRecord>(
        stream: CustomersRecord.getDocument(widget.customerRef!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final customer = snapshot.data!;
          if (customer.isCreditCustomer && !canViewCredit) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'You do not have permission to view credit customer details.',
                  textAlign: TextAlign.center,
                  style: theme.bodyLarge.override(color: theme.secondaryText),
                ),
              ),
            );
          }
          if (_loadingHistory && _history.isEmpty) {
            _loadHistory(customer);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: theme.headlineSmall.override(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (customer.isCreditCustomer) ...[
                          const SizedBox(height: 8),
                          Chip(
                            avatar: const Icon(Icons.receipt_long, size: 18),
                            label: Text(
                              customer.creditTerm.isNotEmpty
                                  ? creditTermShortLabel(customer.creditTerm)
                                  : 'Credit customer',
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _infoRow(Icons.phone, customer.phone),
                        if (customer.uen.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _infoRow(Icons.business, 'UEN: ${customer.uen}'),
                        ],
                        if (customer.billingAddress.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _infoRow(Icons.home, customer.billingAddress),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.isCreditCustomer
                            ? (canManageCredit
                                ? 'Orders (select for invoice)'
                                : 'Orders (view only)')
                            : 'Purchase History',
                        style: theme.titleLarge.override(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (customer.isCreditCustomer &&
                        canManageCredit &&
                        _history.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            final selectable = _history
                                .where(
                                  (entry) =>
                                      isOrderAvailableForInvoicing(entry.order),
                                )
                                .map((e) => e.order.reference.path)
                                .toList();
                            if (_selectedOrderPaths.length ==
                                selectable.length) {
                              _selectedOrderPaths.clear();
                            } else {
                              _selectedOrderPaths
                                ..clear()
                                ..addAll(selectable);
                            }
                          });
                        },
                        child: Text(
                          _selectedOrderPaths.length ==
                                  _history
                                      .where(
                                        (entry) => isOrderAvailableForInvoicing(
                                          entry.order,
                                        ),
                                      )
                                      .length
                              ? 'Clear all'
                              : 'Select all',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loadingHistory)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No previous orders found for this customer.',
                      style: theme.bodyMedium.override(
                        color: theme.secondaryText,
                      ),
                    ),
                  )
                else if (customer.isCreditCustomer && canViewCredit)
                  ..._history.map(
                    (entry) {
                      final invoiceLabel = entry.order.invoiceNumber.isNotEmpty
                          ? '${entry.order.invoiceNumber} (${invoiceStatusLabel(entry.order.invoicePaymentStatus)})'
                          : null;
                      if (!canManageCredit) {
                        return Card(
                          child: ListTile(
                            title: Text(entry.productSummary),
                            subtitle: Text(
                              [
                                if (entry.order.orderId.isNotEmpty)
                                  'Order ${entry.order.orderId}',
                                if (invoiceLabel != null) invoiceLabel,
                                _formatDate(entry.purchasedAt),
                              ].join('\n'),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      }
                      final selectable =
                          isOrderAvailableForInvoicing(entry.order);
                      return Card(
                        child: CheckboxListTile(
                          value: _selectedOrderPaths
                              .contains(entry.order.reference.path),
                          onChanged: selectable
                              ? (checked) =>
                                  _toggleOrderSelection(entry, checked)
                              : null,
                          title: Text(entry.productSummary),
                          subtitle: Text(
                            [
                              if (entry.order.orderId.isNotEmpty)
                                'Order ${entry.order.orderId}',
                              if (invoiceLabel != null) invoiceLabel,
                              _formatDate(entry.purchasedAt),
                            ].join('\n'),
                          ),
                          isThreeLine: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  )
                else
                  ..._history.map(
                    (entry) => Card(
                      child: ListTile(
                        title: Text(entry.productSummary),
                        subtitle: Text(
                          [
                            if (entry.order.orderId.isNotEmpty)
                              'Order ${entry.order.orderId}',
                            _formatDate(entry.purchasedAt),
                          ].join('\n'),
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
                if (customer.isCreditCustomer && canManageCredit) ...[
                  const SizedBox(height: 16),
                  FFButtonWidget(
                    onPressed: _generatingInvoice || _selectedEntries.isEmpty
                        ? null
                        : () => _generateInvoice(customer),
                    text: _generatingInvoice
                        ? 'Generating...'
                        : 'Generate invoice (${_selectedOrderPaths.length})',
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }
}
