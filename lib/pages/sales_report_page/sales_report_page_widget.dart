import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/daily_sales_report_service.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
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
    _resetToToday();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      await _loadReport();
    });
  }

  void _resetToToday() {
    final today = calendarDay(DateTime.now());
    _model.startDate = today;
    _model.endDate = today;
  }

  DateTime get _startDate =>
      calendarDay(_model.startDate ?? DateTime.now());

  DateTime get _endDate => calendarDay(_model.endDate ?? DateTime.now());

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await buildDailySalesReportRange(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _report = report;
        _loading = false;
      });
      await auditLogExportSalesReport(
        startDate: _startDate,
        endDate: _endDate,
        totalOrders: report.totalOrders,
        totalSales: report.totalSalesAmount,
      );
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

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate({
    required DateTime initial,
    required String helpText,
  }) async {
    final today = calendarDay(DateTime.now());
    return showDatePicker(
      context: context,
      helpText: helpText,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(2020),
      lastDate: today,
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await _pickDate(
      initial: _startDate,
      helpText: 'Select start date',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _model.startDate = calendarDay(picked);
      if (_model.endDate != null &&
          calendarDay(_model.endDate!).isBefore(_model.startDate!)) {
        _model.endDate = _model.startDate;
      }
    });
    await _loadReport();
  }

  Future<void> _pickEndDate() async {
    final picked = await _pickDate(
      initial: _endDate,
      helpText: 'Select end date',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _model.endDate = calendarDay(picked);
      if (_model.startDate != null &&
          calendarDay(_model.startDate!).isAfter(_model.endDate!)) {
        _model.startDate = _model.endDate;
      }
    });
    await _loadReport();
  }

  Future<void> _refreshToday() async {
    setState(_resetToToday);
    await _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final start = _startDate;
    final end = _endDate;
    final isToday = isTodayDateRange(start, end);

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
            'Sales Report',
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
              onPressed: _loading ? null : _refreshToday,
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
                      onRefresh: _refreshToday,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDateRangeSelector(
                              theme,
                              start: start,
                              end: end,
                              isToday: isToday,
                            ),
                            const SizedBox(height: 20),
                            _buildProductSection(theme),
                            const SizedBox(height: 20),
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

  Widget _buildDateRangeSelector(
    FlutterFlowTheme theme, {
    required DateTime start,
    required DateTime end,
    required bool isToday,
  }) {
    final sameDay = calendarDay(start) == calendarDay(end);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isToday ? 'Date range (Today)' : 'Date range',
          style: theme.labelMedium.override(color: theme.secondaryText),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateTile(
                theme,
                label: 'From',
                date: start,
                onTap: _pickStartDate,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, color: theme.secondaryText),
            ),
            Expanded(
              child: _buildDateTile(
                theme,
                label: 'To',
                date: end,
                onTap: _pickEndDate,
              ),
            ),
          ],
        ),
        if (!sameDay)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_dateLabel.format(start)} – ${_dateLabel.format(end)}',
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
          ),
      ],
    );
  }

  Widget _buildDateTile(
    FlutterFlowTheme theme, {
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.labelMedium.override(color: theme.secondaryText),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dateLabel.format(date),
                      style: theme.titleSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection(FlutterFlowTheme theme) {
    final products = _report!.productBreakdown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Products',
          style: theme.titleMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: Text(
              'No products sold in this date range.',
              style: theme.bodyMedium.override(color: theme.secondaryText),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: Column(
              children: [
                _productHeaderRow(theme),
                for (var i = 0; i < products.length; i++) ...[
                  Divider(height: 1, color: theme.alternate),
                  _productRow(theme, products[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _productHeaderRow(FlutterFlowTheme theme) {
    TextStyle headerStyle = theme.labelMedium.override(
      font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
      color: theme.secondaryText,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Product name', style: headerStyle),
          ),
          Expanded(
            child: Text(
              'Qty',
              textAlign: TextAlign.center,
              style: headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Total amount',
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productRow(FlutterFlowTheme theme, ProductSalesBreakdown row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.productName,
              style: theme.titleSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.totalQty.toString(),
              textAlign: TextAlign.center,
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currency.format(row.totalAmount),
              textAlign: TextAlign.right,
              style: theme.titleSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                color: theme.primary,
              ),
            ),
          ),
        ],
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
          'No paid orders in this date range.',
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
