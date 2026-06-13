import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/customer_helpers.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/invoice_list_helpers.dart';
import '/backend/order_navigation_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/backend/customer_navigation_helpers.dart';
import '/pages/customer_invoice_confirm_page/customer_invoice_confirm_page_widget.dart';
import '/pages/customer_edit_form/customer_edit_form_widget.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'customer_profile_page_model.dart';
export 'customer_profile_page_model.dart';

class CustomerProfilePageWidget extends StatefulWidget {
  const CustomerProfilePageWidget({
    super.key,
    required this.customerId,
  });

  final String customerId;

  static String routeName = 'CustomerProfilePage';
  static String routePath = '/customer/:customerId';

  static String locationForId(String customerId) => '/customer/$customerId';

  @override
  State<CustomerProfilePageWidget> createState() =>
      _CustomerProfilePageWidgetState();
}

class _CustomerProfilePageWidgetState extends State<CustomerProfilePageWidget>
    with RouteAware {
  late CustomerProfilePageModel _model;
  CustomersRecord? _customer;
  List<CustomerPurchaseEntry> _history = const [];
  bool _loading = true;
  String? _loadError;
  bool _loadingHistory = false;
  bool _deleting = false;
  CustomerOrderPaymentFilter _paymentFilter = CustomerOrderPaymentFilter.all;
  final Set<String> _selectedOrderPaths = {};
  bool _routeObserverSubscribed = false;
  bool _routeVisible = false;

  DocumentReference get _customerRef =>
      CustomersRecord.collection.doc(widget.customerId);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomerProfilePageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAndLoad());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_routeObserverSubscribed && route is PageRoute<void>) {
      appRouteObserver.subscribe(this, route);
      _routeObserverSubscribed = true;
    }

    final isCurrent = route?.isCurrent ?? false;
    if (isCurrent && !_routeVisible) {
      _routeVisible = true;
      if (customerProfileHistoryRefreshPending(widget.customerId)) {
        takeCustomerProfileHistoryRefresh(widget.customerId);
        _refreshOrderHistory();
      }
    } else if (!isCurrent) {
      _routeVisible = false;
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _model.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshOrderHistory();
  }

  Future<void> _refreshOrderHistory() async {
    final customer = _customer;
    if (customer == null || !mounted) {
      return;
    }
    await _loadHistory(customer);
  }

  Future<void> _bootstrapAndLoad() async {
    if (loggedIn) {
      final profile = await resolveCurrentUserProfile();
      await TenantContext.instance.initialize(profile);
    }
    await _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final customer = await CustomersRecord.getDocumentOnce(_customerRef);
      if (!mounted) {
        return;
      }
      setState(() {
        _customer = customer;
        _loading = false;
      });
      await _loadHistory(customer);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = describeFirestoreError(error);
      });
    }
  }

  Future<void> _loadHistory(CustomersRecord customer) async {
    setState(() => _loadingHistory = true);
    try {
      final history = await enrichCustomerPurchaseEntriesForInvoicing(
        await loadCustomerPurchaseHistory(customer),
      );
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

  List<CustomerPurchaseEntry> get _filteredHistory => _history
      .where(
        (entry) => matchesCustomerOrderPaymentFilter(
          entry.order,
          _paymentFilter,
        ),
      )
      .toList();

  List<CustomerPurchaseEntry> get _selectedEntries => _history
      .where((entry) => _selectedOrderPaths.contains(entry.order.reference.path))
      .toList();

  CustomerPurchaseSummary get _purchaseSummary =>
      summarizeCustomerPurchaseHistory(_history);

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return DateFormat('d MMM yyyy, HH:mm').format(date);
  }

  String _formatPurchaseDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return DateFormat('d MMM yyyy').format(date);
  }

  String _orderPaymentLabel(OrdersRecord order) {
    if (order.invoiceNumber.isNotEmpty) {
      return '${order.invoiceNumber} · ${invoiceStatusLabel(order.invoicePaymentStatus)}';
    }
    if (order.invoicePaymentStatus.trim().toLowerCase() ==
        InvoiceStatus.voided) {
      return 'Previous invoice voided · Unpaid';
    }
    return isCustomerOrderPaid(order) ? 'Paid' : 'Unpaid';
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

  Future<void> _generateInvoice(CustomersRecord customer) async {
    if (_selectedEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one order.')),
      );
      return;
    }

    final created = await CustomerInvoiceConfirmPageWidget.show(
      context,
      customer: customer,
      entries: _selectedEntries,
    );
    if (!mounted || created != true) {
      return;
    }
    setState(() => _selectedOrderPaths.clear());
    await _loadHistory(customer);
  }

  Future<void> _openEditProfile() async {
    final updated = await context.pushNamed(
      CustomerEditFormWidget.routeName,
      queryParameters: {'customerId': widget.customerId},
    );
    if (!mounted || updated != true) {
      return;
    }
    await _loadCustomer();
  }

  Future<void> _confirmDeleteCustomer(CustomersRecord customer) async {
    final theme = FlutterFlowTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text(
          'Delete ${customer.name}${customer.customerId.isNotEmpty ? ' (${customer.customerId})' : ''}? '
          'Their customer number can be reused. Order history stays on past orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }

    setState(() => _deleting = true);
    try {
      await deleteCustomerProfile(customer);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            customer.customerId.isNotEmpty
                ? 'Customer deleted. ${customer.customerId} is available again.'
                : 'Customer deleted.',
          ),
        ),
      );
      goToCustomerList(context);
    } catch (error) {
      if (mounted) {
        final message = error is CustomerWriteException
            ? error.message
            : 'Failed to delete customer: ${describeFirestoreError(error)}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canManageCredit =
        canManageCreditAndInvoices(currentViewerRole());
    final canViewCredit =
        canViewCreditAndInvoices(currentViewerRole());
    final canEdit = canEditCustomers(currentViewerRole());
    final canDelete = canDeleteCustomers(currentViewerRole());

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          onPressed: () => exitCustomerProfile(context),
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
      body: _buildBody(
        theme,
        canManageCredit,
        canViewCredit,
        canEdit,
        canDelete,
      ),
    );
  }

  Widget _buildBody(
    FlutterFlowTheme theme,
    bool canManageCredit,
    bool canViewCredit,
    bool canEdit,
    bool canDelete,
  ) {
    if (widget.customerId.isEmpty) {
      return const Center(child: Text('Customer not found'));
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
                'Could not load customer.',
                style: theme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                style: theme.bodyMedium.override(color: theme.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _bootstrapAndLoad,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final customer = _customer;
    if (customer == null) {
      return const Center(child: Text('Customer not found'));
    }
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

    final isCredit = customer.isCreditCustomer;
    final showInvoiceSelection = isCredit && canCreateInvoices(currentViewerRole());

    return RefreshIndicator(
      onRefresh: () async {
        await _loadCustomer();
      },
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
                    customer.name,
                    style: theme.headlineSmall.override(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (customer.customerId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      customer.customerId,
                      style: theme.titleSmall.override(
                        color: theme.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (isCredit) ...[
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
                  _purchaseSummaryRow(theme),
                  const SizedBox(height: 12),
                  _infoRow(Icons.phone, customer.phone),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.email_outlined,
                    customer.email.isNotEmpty ? customer.email : '-',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.cake_outlined,
                    customer.hasBirthday()
                        ? formatCustomerBirthday(customer.birthday)
                        : '-',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.home_outlined,
                    customer.billingAddress.isNotEmpty
                        ? customer.billingAddress
                        : '-',
                  ),
                  if (customer.uen.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _infoRow(Icons.business, 'UEN: ${customer.uen}'),
                  ],
                  if (canEdit || canDelete) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (canEdit)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _deleting ? null : _openEditProfile,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit profile'),
                            ),
                          ),
                        if (canEdit && canDelete) const SizedBox(width: 12),
                        if (canDelete)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _deleting
                                  ? null
                                  : () => _confirmDeleteCustomer(customer),
                              icon: _deleting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(Icons.delete_outline, color: theme.error),
                              label: Text(
                                _deleting ? 'Deleting…' : 'Delete',
                                style: TextStyle(color: theme.error),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Order History',
            style: theme.titleLarge.override(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SegmentedButton<CustomerOrderPaymentFilter>(
            segments: const [
              ButtonSegment(
                value: CustomerOrderPaymentFilter.all,
                label: Text('All'),
              ),
              ButtonSegment(
                value: CustomerOrderPaymentFilter.unpaid,
                label: Text('Unpaid'),
              ),
              ButtonSegment(
                value: CustomerOrderPaymentFilter.paid,
                label: Text('Paid'),
              ),
            ],
            selected: {_paymentFilter},
            onSelectionChanged: (selection) {
              setState(() => _paymentFilter = selection.first);
            },
          ),
          if (showInvoiceSelection && _filteredHistory.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    final selectable = _filteredHistory
                        .where(
                          (entry) => customerPurchaseEntryCanInvoice(entry),
                        )
                        .map((e) => e.order.reference.path)
                        .toList();
                    if (_selectedOrderPaths.length == selectable.length) {
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
                          _filteredHistory
                              .where(
                                (entry) => customerPurchaseEntryCanInvoice(
                                  entry,
                                ),
                              )
                              .length
                      ? 'Clear selection'
                      : 'Select unpaid for invoice',
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (_loadingHistory)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _paymentFilter == CustomerOrderPaymentFilter.all
                    ? 'No orders found for this customer.'
                    : 'No ${_paymentFilter.name} orders.',
                style: theme.bodyMedium.override(color: theme.secondaryText),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._filteredHistory.map(
              (entry) => _orderTile(
                theme: theme,
                entry: entry,
                showCheckbox: showInvoiceSelection,
              ),
            ),
          if (showInvoiceSelection) ...[
            const SizedBox(height: 16),
            FFButtonWidget(
              onPressed: _selectedEntries.isEmpty
                  ? null
                  : () => _generateInvoice(customer),
              text: 'Create invoice (${_selectedOrderPaths.length})',
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
  }

  Widget _orderTile({
    required FlutterFlowTheme theme,
    required CustomerPurchaseEntry entry,
    required bool showCheckbox,
  }) {
    final order = entry.order;
    final paid = isCustomerOrderPaid(order);
    final subtitle = [
      if (order.orderId.isNotEmpty) 'Order ${order.orderId}',
      _orderPaymentLabel(order),
      _formatDate(entry.purchasedAt),
    ].join('\n');

    final trailing = Chip(
      label: Text(
        paid ? 'Paid' : 'Unpaid',
        style: theme.bodySmall.override(
          color: paid ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: paid
          ? const Color(0xFFE8F5E9)
          : const Color(0xFFFFEBEE),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );

    if (!showCheckbox) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(entry.productSummary),
          subtitle: Text(subtitle),
          isThreeLine: true,
          trailing: trailing,
          onTap: () => openOrderDetail(context, order.reference),
        ),
      );
    }

    final selectable = customerPurchaseEntryCanInvoice(entry);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => openOrderDetail(context, order.reference),
        child: CheckboxListTile(
          value: _selectedOrderPaths.contains(order.reference.path),
          onChanged: selectable
              ? (checked) => _toggleOrderSelection(entry, checked)
              : null,
          title: Text(entry.productSummary),
          subtitle: Text(subtitle),
          isThreeLine: true,
          controlAffinity: ListTileControlAffinity.leading,
        ),
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

  Widget _purchaseSummaryRow(FlutterFlowTheme theme) {
    final summary = _purchaseSummary;
    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            theme: theme,
            label: 'Total spending',
            value: _loadingHistory
                ? '…'
                : formatCashMoney(summary.totalSpending),
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryTile(
            theme: theme,
            label: 'Last purchase',
            value: _loadingHistory
                ? '…'
                : _formatPurchaseDate(summary.lastPurchaseAt),
            icon: Icons.shopping_bag_outlined,
          ),
        ),
      ],
    );
  }

  Widget _summaryTile({
    required FlutterFlowTheme theme,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.secondaryText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.labelMedium.override(color: theme.secondaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.titleMedium.override(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
