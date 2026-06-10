import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/customer_broadcast_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/backend/tenant_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'customer_list_page_model.dart';
export 'customer_list_page_model.dart';

class CustomerListPageWidget extends StatefulWidget {
  const CustomerListPageWidget({super.key});

  static String routeName = 'CustomerListPage';
  static String routePath = '/customerListPage';

  @override
  State<CustomerListPageWidget> createState() => _CustomerListPageWidgetState();
}

class _CustomerListPageWidgetState extends State<CustomerListPageWidget> {
  late CustomerListPageModel _model;
  List<CustomersRecord> _customers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomerListPageModel());
    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomers());
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    try {
      final customers = await queryTenantCustomersRecordOnce(
        queryBuilder: (query) => query.orderBy('name'),
        limit: 500,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _customers = customers;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<CustomersRecord> get _filteredCustomers {
    final query = _model.searchController!.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _customers;
    }
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.phone.contains(query) ||
          customer.billingAddress.toLowerCase().contains(query) ||
          customer.uen.toLowerCase().contains(query);
    }).toList();
  }

  void _openProfile(CustomersRecord customer) {
    context.pushNamed(
      CustomerProfilePageWidget.routeName,
      queryParameters: {
        'customerRef': serializeParam(
          customer.reference,
          ParamType.DocumentReference,
        )!,
      },
      extra: {'customerRef': customer.reference},
    );
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
      appBar: AppBar(
        backgroundColor: theme.primary,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Customers',
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined, color: Colors.white),
            tooltip: 'Broadcast',
            onPressed: _filteredCustomers.isEmpty
                ? null
                : () => showCustomerBroadcastDialog(
                      context: context,
                      customers: _filteredCustomers,
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            onPressed: () =>
                context.pushNamed(CustomerCreateFormWidget.routeName),
          ),
          const HomeNavIconButton(),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _model.searchController,
                    focusNode: _model.searchFocusNode,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search name, phone, address',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (!_loading && _filteredCustomers.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => showCustomerBroadcastDialog(
                        context: context,
                        customers: _filteredCustomers,
                      ),
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('Broadcast Message'),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCustomers.isEmpty
                      ? Center(
                          child: Text(
                            'No customers yet',
                            style: theme.bodyLarge,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCustomers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            return Card(
                              child: ListTile(
                                title: Text(customer.name),
                                subtitle: Text(
                                  '${customer.phone}\n${customer.billingAddress}',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openProfile(customer),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(CustomerCreateFormWidget.routeName),
        icon: const Icon(Icons.person_add),
        label: const Text('New Customer'),
      ),
    );
  }
}
