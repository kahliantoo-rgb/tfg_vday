import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/daily_sales_report_service.dart';
import '/backend/profit_summary_report_service.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'profit_summary_report_page_model.dart';
export 'profit_summary_report_page_model.dart';

class ProfitSummaryReportPageWidget extends StatefulWidget {
  const ProfitSummaryReportPageWidget({super.key});

  static String routeName = 'ProfitSummaryReportPage';
  static String routePath = '/profitSummaryReportPage';

  @override
  State<ProfitSummaryReportPageWidget> createState() =>
      _ProfitSummaryReportPageWidgetState();
}

class _ProfitSummaryReportPageWidgetState
    extends State<ProfitSummaryReportPageWidget> {
  late ProfitSummaryReportPageModel _model;
  final _currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
  final _dateLabel = DateFormat('EEE, d MMM yyyy');
  final _utilityController = TextEditingController();
  final _salaryController = TextEditingController();
  final _adhocAmountController = TextEditingController();
  final _adhocRemarkController = TextEditingController();

  ProfitSummaryReportData? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfitSummaryReportPageModel());
    _resetToToday();
    for (final controller in [
      _utilityController,
      _salaryController,
      _adhocAmountController,
    ]) {
      controller.addListener(_onManualExpenseChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      await _loadReport();
    });
  }

  void _onManualExpenseChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _resetToToday() {
    final today = calendarDay(DateTime.now());
    _model.startDate = today;
    _model.endDate = today;
  }

  DateTime get _startDate =>
      calendarDay(_model.startDate ?? DateTime.now());

  DateTime get _endDate => calendarDay(_model.endDate ?? DateTime.now());

  double get _utilityExpense => parseExpenseInput(_utilityController.text);

  double get _staffSalaryClaim => parseExpenseInput(_salaryController.text);

  double get _adhocExpense => parseExpenseInput(_adhocAmountController.text);

  double get _totalExpenses {
    final report = _report;
    if (report == null) {
      return 0;
    }
    return calculateTotalExpenses(
      materialUsageCost: report.materialUsageCost,
      utilityExpense: _utilityExpense,
      staffSalaryClaim: _staffSalaryClaim,
      adhocExpense: _adhocExpense,
    );
  }

  double get _netProfit {
    final report = _report;
    if (report == null) {
      return 0;
    }
    return calculateNetProfit(
      totalSalesAmount: report.totalSalesAmount,
      materialUsageCost: report.materialUsageCost,
      utilityExpense: _utilityExpense,
      staffSalaryClaim: _staffSalaryClaim,
      adhocExpense: _adhocExpense,
    );
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await buildProfitSummaryReportDataRange(
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
    for (final controller in [
      _utilityController,
      _salaryController,
      _adhocAmountController,
      _adhocRemarkController,
    ]) {
      controller.dispose();
    }
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
            borderRadius: 30.0,
            buttonSize: 60.0,
            icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText),
            onPressed: () => context.safePop(),
          ),
          title: Text(
            'Profit Summary',
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
                            _buildSummaryCards(theme),
                            const SizedBox(height: 20),
                            _buildManualExpenseSection(theme),
                            const SizedBox(height: 20),
                            _buildCalculationSection(theme),
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
            Text(_error!, textAlign: TextAlign.center, style: theme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadReport, child: const Text('Retry')),
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.labelMedium.override(color: theme.secondaryText),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.titleMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualExpenseSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Manual expenses',
          style: theme.titleMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter amounts for this period. Material cost is calculated automatically.',
          style: theme.bodySmall.override(color: theme.secondaryText),
        ),
        const SizedBox(height: 12),
        _expenseField(
          theme,
          label: 'Utility expense',
          controller: _utilityController,
          hint: '0.00',
        ),
        const SizedBox(height: 12),
        _expenseField(
          theme,
          label: 'Total staff salary claim',
          controller: _salaryController,
          hint: '0.00',
        ),
        const SizedBox(height: 12),
        _expenseField(
          theme,
          label: 'Adhoc expense',
          controller: _adhocAmountController,
          hint: '0.00',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _adhocRemarkController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Adhoc remark',
            hintText: 'Optional note for adhoc expense',
            filled: true,
            fillColor: theme.secondaryBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.alternate),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.alternate),
            ),
          ),
        ),
      ],
    );
  }

  Widget _expenseField(
    FlutterFlowTheme theme, {
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: r'$ ',
        filled: true,
        fillColor: theme.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.alternate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.alternate),
        ),
      ),
    );
  }

  Widget _buildCalculationSection(FlutterFlowTheme theme) {
    final report = _report!;
    final adhocRemark = _adhocRemarkController.text.trim();
    final netColor = _netProfit >= 0 ? theme.success : theme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Summary',
            style: theme.titleMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          _calcRow(
            theme,
            label: 'Total sales',
            value: formatCashMoney(report.totalSalesAmount),
            valueColor: theme.success,
            prefix: '+',
          ),
          const Divider(height: 20),
          _calcRow(
            theme,
            label: 'Material usage cost',
            value: formatCashMoney(report.materialUsageCost),
            prefix: '−',
          ),
          _calcRow(
            theme,
            label: 'Utility expense',
            value: formatCashMoney(_utilityExpense),
            prefix: '−',
          ),
          _calcRow(
            theme,
            label: 'Staff salary claim',
            value: formatCashMoney(_staffSalaryClaim),
            prefix: '−',
          ),
          _calcRow(
            theme,
            label: 'Adhoc expense',
            value: formatCashMoney(_adhocExpense),
            prefix: '−',
            subtitle: adhocRemark.isNotEmpty ? adhocRemark : null,
          ),
          const Divider(height: 20),
          _calcRow(
            theme,
            label: 'Total expenses',
            value: formatCashMoney(_totalExpenses),
            valueColor: theme.error,
          ),
          const SizedBox(height: 8),
          _calcRow(
            theme,
            label: 'Net profit',
            value: formatCashMoney(_netProfit),
            valueColor: netColor,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _calcRow(
    FlutterFlowTheme theme, {
    required String label,
    required String value,
    String? prefix,
    String? subtitle,
    Color? valueColor,
    bool isTotal = false,
  }) {
    final labelStyle = isTotal
        ? theme.titleMedium.override(fontWeight: FontWeight.w700)
        : theme.bodyLarge;
    final valueStyle = (isTotal ? theme.titleLarge : theme.titleSmall).override(
      font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
      color: valueColor ?? theme.primaryText,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prefix != null)
            SizedBox(
              width: 16,
              child: Text(prefix, style: theme.bodyLarge),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.bodySmall.override(color: theme.secondaryText),
                  ),
              ],
            ),
          ),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
