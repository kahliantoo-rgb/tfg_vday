import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/create_order_service.dart';
import '/backend/customer_helpers.dart';
import '/backend/customer_navigation_helpers.dart';
import '/backend/customer_broadcast_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
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
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomerListPageModel());
    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAndLoad());
  }

  Future<void> _bootstrapAndLoad() async {
    if (loggedIn) {
      final profile = await resolveCurrentUserProfile();
      await TenantContext.instance.initialize(profile);
    }
    await _loadCustomers();
  }

  Future<void> _loadCustomers({DocumentReference? ensureVisibleRef}) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      var customers = await queryCustomersForTenantList();
      if (ensureVisibleRef != null &&
          !customers.any((c) => c.reference.path == ensureVisibleRef.path)) {
        try {
          final created =
              await CustomersRecord.getDocumentOnce(ensureVisibleRef);
          if (customerBelongsToActiveTenant(created)) {
            customers = [...customers, created]..sort(_compareCustomerName);
          }
        } catch (_) {
          // Fall back to list query result only.
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _customers = customers;
        _loading = false;
      });
      if (customers.any((c) => c.customerId.isEmpty)) {
        backfillMissingCustomerPublicIds().then((_) {
          if (mounted) {
            _loadCustomers();
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _customers = const [];
          _loading = false;
          _loadError = describeFirestoreError(error);
        });
      }
    }
  }

  int _compareCustomerName(CustomersRecord a, CustomersRecord b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  List<CustomersRecord> get _filteredCustomers {
    final query = _model.searchController!.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _customers;
    }
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.customerId.toLowerCase().contains(query) ||
          customer.phone.contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.billingAddress.toLowerCase().contains(query) ||
          customer.uen.toLowerCase().contains(query);
    }).toList();
  }

  void _openProfile(CustomersRecord customer) async {
    await openCustomerProfile(context, customer.reference);
    if (mounted) {
      await _loadCustomers();
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
      appBar: AppBar(
        backgroundColor: theme.primary,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(SalesDashBoardWidget.routePath);
            }
          },
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
                      hintText: 'Search name, phone, email, address',
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
                  : _loadError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Could not load customers.',
                                  style: theme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _loadError!,
                                  style: theme.bodySmall.override(
                                    color: theme.secondaryText,
                                  ),
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
                        )
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
                            final subtitleParts = <String>[
                              if (customer.customerId.isNotEmpty)
                                customer.customerId,
                              if (customer.phone.isNotEmpty) customer.phone,
                              if (customer.email.isNotEmpty) customer.email,
                              if (customer.billingAddress.isNotEmpty)
                                customer.billingAddress,
                            ];
                            return Card(
                              child: ListTile(
                                title: Text(customer.name),
                                subtitle: Text(subtitleParts.join('\n')),
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
        onPressed: () async {
          await context.pushNamed(
            CustomerCreateFormWidget.routeName,
          );
          if (!mounted) {
            return;
          }
          final createdRef = takePendingCreatedCustomerRef();
          await _loadCustomers(ensureVisibleRef: createdRef);
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }
}
