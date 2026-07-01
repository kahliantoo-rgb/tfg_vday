import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/customer_helpers.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/customer_validation_display.dart';
import '/backend/invoice_list_helpers.dart';
import '/backend/invoice_status_display.dart';
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
      final customer = await loadCustomerProfileRecord(_customerRef);
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
        _loadError = error is CustomerWriteException
            ? error.message
            : describeFirestoreError(error);
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
      return '${order.invoiceNumber} · ${invoiceStatusDisplayLabel(context, order.invoicePaymentStatus)}';
    }
    if (order.invoicePaymentStatus.trim().toLowerCase() ==
        InvoiceStatus.voided) {
      return tr(context, 'customer.profile.prevVoidUnpaid');
    }
    return isCustomerOrderPaid(order)
        ? tr(context, 'common.paid')
        : tr(context, 'common.unpaid');
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
        SnackBar(content: Text(tr(context, 'customer.profile.selectOrder'))),
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
        title: Text(tr(context, 'customer.delete.title')),
        content: Text(
          tr(context, 'customer.delete.body', params: {
            'name': customer.name,
            'idSuffix': customer.customerId.isNotEmpty
                ? tr(context, 'customer.delete.idSuffix',
                    params: {'id': customer.customerId})
                : '',
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tr(context, 'common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(tr(context, 'common.delete')),
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
                ? tr(context, 'customer.delete.successWithId',
                    params: {'id': customer.customerId})
                : tr(context, 'customer.delete.success'),
          ),
        ),
      );
      goToCustomerList(context);
    } catch (error) {
      if (mounted) {
        final message = error is CustomerWriteException
            ? error.message
            : tr(context, 'customer.delete.failed',
                params: {'error': describeFirestoreError(error)});
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
          tr(context, 'customer.profile.title'),
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: const [AppBarLanguageHomeActions()],
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
      return Center(child: Text(tr(context, 'customer.profile.notFound')));
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
                tr(context, 'customer.profile.loadError'),
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
                child: Text(tr(context, 'common.retry')),
              ),
            ],
          ),
        ),
      );
    }

    final customer = _customer;
    if (customer == null) {
      return Center(child: Text(tr(context, 'customer.profile.notFound')));
    }
    if (customer.isCreditCustomer && !canViewCredit) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            tr(context, 'customer.profile.noCreditPermission'),
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
                            : tr(context, 'customer.profile.creditCustomer'),
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
                        ? formatCustomerBirthdayLocalized(context, customer.birthday)
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
                    _infoRow(
                      Icons.business,
                      tr(context, 'customer.profile.uenLine',
                          params: {'uen': customer.uen}),
                    ),
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
                              label: Text(tr(context, 'customer.profile.editProfile')),
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
                                _deleting
                                    ? tr(context, 'common.deleting')
                                    : tr(context, 'common.delete'),
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
            tr(context, 'customer.profile.orderHistory'),
            style: theme.titleLarge.override(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SegmentedButton<CustomerOrderPaymentFilter>(
            segments: [
              ButtonSegment(
                value: CustomerOrderPaymentFilter.all,
                label: Text(tr(context, 'common.all')),
              ),
              ButtonSegment(
                value: CustomerOrderPaymentFilter.unpaid,
                label: Text(tr(context, 'common.unpaid')),
              ),
              ButtonSegment(
                value: CustomerOrderPaymentFilter.paid,
                label: Text(tr(context, 'common.paid')),
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
                      ? tr(context, 'customer.profile.clearSelection')
                      : tr(context, 'customer.profile.selectUnpaidForInvoice'),
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
                    ? tr(context, 'customer.profile.noOrders')
                    : tr(context, 'customer.profile.noFilteredOrders', params: {
                        'filter': customerOrderPaymentFilterLabel(
                          context,
                          _paymentFilter,
                        ),
                      }),
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
              text: tr(context, 'customer.profile.createInvoice',
                  params: {'count': '${_selectedOrderPaths.length}'}),
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
      if (order.orderId.isNotEmpty)
        tr(context, 'customer.profile.orderLine',
            params: {'orderId': order.orderId}),
      _orderPaymentLabel(order),
      _formatDate(entry.purchasedAt),
      if (!showCheckbox) tr(context, 'customer.profile.tapForDetails'),
    ].join('\n');

    final statusChip = Chip(
      label: Text(
        paid ? tr(context, 'common.paid') : tr(context, 'common.unpaid'),
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

    final selectable = customerPurchaseEntryCanInvoice(entry);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => openOrderDetail(context, order.reference),
        leading: showCheckbox
            ? Checkbox(
                value: _selectedOrderPaths.contains(order.reference.path),
                onChanged: selectable
                    ? (checked) => _toggleOrderSelection(entry, checked)
                    : null,
                activeColor: theme.primary,
              )
            : null,
        title: Text(entry.productSummary),
        subtitle: Text(subtitle),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            statusChip,
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: theme.primary),
          ],
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
            label: tr(context, 'customer.profile.totalSpending'),
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
            label: tr(context, 'customer.profile.lastPurchase'),
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
