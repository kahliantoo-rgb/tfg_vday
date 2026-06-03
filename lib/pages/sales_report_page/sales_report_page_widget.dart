import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/backend/daily_sales_report_service.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'sales_report_page_model.dart';
export 'sales_report_page_model.dart';

class SalesReportPageWidget extends StatefulWidget {
  const SalesReportPageWidget({super.key});

  static String routeName = 'SalesReportPage';
  static String routePath = '/salesReportPage';

  @override
  State<SalesReportPageWidget> createState() => _SalesReportPageWidgetState();
}

class _SalesReportPageWidgetState extends State<SalesReportPageWidget> {
  late SalesReportPageModel _model;
  final _currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
  final _dateLabel = DateFormat('EEE, d MMM yyyy');

  DailySalesReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SalesReportPageModel());
    _model.selectedDate = DateTime.now();
    _loadReport();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    final day = _model.selectedDate ?? DateTime.now();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await buildDailySalesReport(day);
      if (!mounted) {
        return;
      }
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final initial = _model.selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() => _model.selectedDate = picked);
    await _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final day = _model.selectedDate ?? DateTime.now();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: theme.primaryText,
              size: 30.0,
            ),
            onPressed: () => context.safePop(),
          ),
          title: Text(
            'Daily Sales Report',
            style: theme.headlineMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              fontSize: 22.0,
            ),
          ),
          actions: [
            FlutterFlowIconButton(
              borderRadius: 20.0,
              buttonSize: 40.0,
              icon: Icon(Icons.refresh, color: theme.primaryText, size: 24.0),
              onPressed: _loading ? null : _loadReport,
            ),
            const HomeNavIconButton(),
          ],
          elevation: 0.0,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError(theme)
                  : RefreshIndicator(
                      onRefresh: _loadReport,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDateSelector(theme, day),
                            const SizedBox(height: 16),
                            _buildSummaryCards(theme),
                            const SizedBox(height: 20),
                            Text(
                              'Payment methods',
                              style: theme.titleMedium.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentSection(theme),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildError(FlutterFlowTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.error),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadReport,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(FlutterFlowTheme theme, DateTime day) {
    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _pickDate,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: theme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report date',
                      style: theme.labelMedium.override(
                        color: theme.secondaryText,
                      ),
                    ),
                    Text(
                      _dateLabel.format(day),
                      style: theme.titleMedium.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(FlutterFlowTheme theme) {
    final report = _report!;
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            theme,
            label: 'Total orders',
            value: report.totalOrders.toString(),
            icon: Icons.receipt_long_outlined,
            color: theme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            theme,
            label: 'Total sales',
            value: _currency.format(report.totalSalesAmount),
            icon: Icons.payments_outlined,
            color: theme.success,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(
    FlutterFlowTheme theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.labelMedium.override(color: theme.secondaryText),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.headlineSmall.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(FlutterFlowTheme theme) {
    final breakdown = _report!.paymentBreakdown;
    if (breakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.alternate),
        ),
        child: Text(
          'No paid orders on this date.',
          style: theme.bodyMedium.override(color: theme.secondaryText),
        ),
      );
    }

    return Column(
      children: breakdown
          .map((row) => _paymentRow(theme, row))
          .toList(growable: false),
    );
  }

  Widget _paymentRow(FlutterFlowTheme theme, PaymentMethodBreakdown row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.alternate),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row.label} total',
                    style: theme.titleSmall.override(
                      font: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${row.orderCount} order${row.orderCount == 1 ? '' : 's'}',
                    style: theme.bodySmall.override(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _currency.format(row.totalAmount),
              style: theme.titleMedium.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                color: theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
