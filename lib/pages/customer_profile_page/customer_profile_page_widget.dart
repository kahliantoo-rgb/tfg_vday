import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/backend/customer_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomerProfilePageModel());
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

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
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
                        const SizedBox(height: 12),
                        _infoRow(Icons.phone, customer.phone),
                        const SizedBox(height: 8),
                        _infoRow(Icons.home, customer.billingAddress),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Purchase History',
                  style: theme.titleLarge.override(fontWeight: FontWeight.bold),
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
