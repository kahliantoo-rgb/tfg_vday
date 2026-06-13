import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/daily_sales_report_service.dart';
import '/backend/material_usage_report_service.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'material_usage_report_page_model.dart';
export 'material_usage_report_page_model.dart';

class MaterialUsageReportPageWidget extends StatefulWidget {
  const MaterialUsageReportPageWidget({super.key});

  static String routeName = 'MaterialUsageReportPage';
  static String routePath = '/materialUsageReportPage';

  @override
  State<MaterialUsageReportPageWidget> createState() =>
      _MaterialUsageReportPageWidgetState();
}

class _MaterialUsageReportPageWidgetState
    extends State<MaterialUsageReportPageWidget> {
  late MaterialUsageReportPageModel _model;
  final _dateLabel = DateFormat('EEE, d MMM yyyy');

  DailyMaterialUsageReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MaterialUsageReportPageModel());
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
      final report = await buildMaterialUsageReportRange(
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
            'Material Usage',
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
                            const SizedBox(height: 16),
                            Text(
                              'Estimated from paid orders × product recipes.',
                              style: theme.bodySmall.override(
                                color: theme.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryCards(theme),
                            const SizedBox(height: 20),
                            _buildMaterialSection(theme),
                            const SizedBox(height: 20),
                            _buildUnmatchedSection(theme),
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
          child: _summaryCard(
            theme,
            label: 'Paid orders',
            value: '${report.totalPaidOrders}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            theme,
            label: 'Materials used',
            value: '${report.materialBreakdown.length}',
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    FlutterFlowTheme theme, {
    required String label,
    required String value,
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
          Text(
            label,
            style: theme.labelMedium.override(color: theme.secondaryText),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.headlineSmall.override(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialSection(FlutterFlowTheme theme) {
    final materials = _report!.materialBreakdown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Materials',
          style: theme.titleMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        if (materials.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: Text(
              'No material usage for this date range. '
              'Add recipes to products or check paid orders.',
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
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Material',
                          style: theme.labelLarge.override(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Qty',
                          textAlign: TextAlign.end,
                          style: theme.labelLarge.override(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                for (final row in materials)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(row.materialName, style: theme.bodyLarge),
                              if (row.unit.isNotEmpty)
                                Text(
                                  row.unit,
                                  style: theme.bodySmall.override(
                                    color: theme.secondaryText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            formatMaterialUsageQty(row.totalQty),
                            textAlign: TextAlign.end,
                            style: theme.titleMedium.override(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUnmatchedSection(FlutterFlowTheme theme) {
    final unmatched = _report!.unmatchedProducts;
    if (unmatched.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sold without recipe',
          style: theme.titleMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'These products were sold but have no recipe linked yet.',
          style: theme.bodySmall.override(color: theme.secondaryText),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.alternate),
          ),
          child: Column(
            children: [
              for (final row in unmatched)
                ListTile(
                  title: Text(row.productName),
                  trailing: Text('${row.totalQty} sold'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
