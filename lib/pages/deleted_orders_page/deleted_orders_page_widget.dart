import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/deleted_orders_helpers.dart';
import '/backend/order_delete_service.dart';
import '/backend/order_restore_service.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'deleted_orders_page_model.dart';
export 'deleted_orders_page_model.dart';

class DeletedOrdersPageWidget extends StatefulWidget {
  const DeletedOrdersPageWidget({super.key});

  static String routeName = 'DeletedOrdersPage';
  static String routePath = '/deletedOrdersPage';

  @override
  State<DeletedOrdersPageWidget> createState() => _DeletedOrdersPageWidgetState();
}

class _DeletedOrdersPageWidgetState extends State<DeletedOrdersPageWidget> {
  late DeletedOrdersPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<DeletedOrdersRecord> _allRecords = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DeletedOrdersPageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      await _loadRecords();
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final role = AppStateNotifier.instance.userRole;
    if (!canViewDeletedOrders(role)) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _allRecords = const [];
        _error = '__no_permission__';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final records = await queryTenantDeletedOrdersRecordOnce();
      if (!mounted) {
        return;
      }
      setState(() {
        _allRecords = records;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '__load_failed__';
      });
    }
  }

  List<DeletedOrdersRecord> get _filteredRecords => filterDeletedOrders(
        records: _allRecords,
        searchQuery: _model.searchController?.text ?? '',
        deletedFrom: _model.deletedFrom,
        deletedTo: _model.deletedTo,
        deletedByEmail: _model.deletedByFilter,
        statusFilter: _model.statusFilter,
      );

  DeletedOrdersPageSlice get _pageSlice => paginateDeletedOrders(
        records: _filteredRecords,
        pageIndex: _model.pageIndex,
      );

  DeletedOrdersAnalytics get _analytics =>
      computeDeletedOrdersAnalytics(_allRecords);

  void _resetPageAndRefresh() {
    _model.pageIndex = 0;
    safeSetState(() {});
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_model.deletedFrom ?? DateTime.now())
        : (_model.deletedTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isFrom) {
        _model.deletedFrom = picked;
      } else {
        _model.deletedTo = picked;
      }
      _model.pageIndex = 0;
    });
  }

  Future<void> _confirmRestore(DeletedOrdersRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'order.deleted.restoreTitle')),
        content: Text(
          tr(context, 'order.deleted.restoreBody', params: {
            'orderId': record.orderId.isNotEmpty
                ? record.orderId
                : record.originalOrderId,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(context, 'order.deleted.restore')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await restoreDeletedOrder(record);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'order.deleted.restoreSuccess')),
          backgroundColor: FlutterFlowTheme.of(context).secondary,
        ),
      );
      await _loadRecords();
    } on OrderRestoreException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'order.deleted.restoreFailed'))),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirmPermanentDelete(DeletedOrdersRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'order.deleted.permanentTitle')),
        content: Text(tr(context, 'order.deleted.permanentBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: FlutterFlowTheme.of(context).error,
            ),
            child: Text(tr(context, 'order.deleted.permanentButton')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await permanentlyDeleteArchivedOrder(record);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'order.deleted.permanentSuccess'))),
      );
      await _loadRecords();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'order.deleted.permanentFailed'))),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final role = AppStateNotifier.instance.userRole;
    final canRestore = canRestoreDeletedOrders(role);
    final canPermanentDelete = canPermanentlyDeleteDeletedOrders(role);
    final deleterOptions = uniqueDeletedByEmails(_allRecords);
    final slice = _pageSlice;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            buttonSize: 46.0,
            icon: Icon(Icons.arrow_back_rounded, color: theme.info, size: 25.0),
            onPressed: () => context.safePop(),
          ),
          title: Text(
            tr(context, 'order.deleted.title'),
            style: theme.headlineMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              color: theme.info,
              fontSize: 22.0,
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 0, 12, 0),
              child: HomeNavIconButton(),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: Stack(
          children: [
            SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            switch (_error) {
                              '__no_permission__' =>
                                tr(context, 'order.deleted.noPermission'),
                              '__load_failed__' =>
                                tr(context, 'order.deleted.loadFailed'),
                              _ => _error!,
                            },
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRecords,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildAnalyticsCards(theme, wide),
                                const SizedBox(height: 16),
                                _buildFilters(theme, deleterOptions),
                                const SizedBox(height: 16),
                                if (slice.items.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 48),
                                    child: Text(
                                      tr(context, 'order.deleted.noMatch'),
                                      textAlign: TextAlign.center,
                                      style: theme.bodyLarge,
                                    ),
                                  )
                                else if (wide)
                                  _buildTable(
                                    theme,
                                    slice.items,
                                    canRestore: canRestore,
                                    canPermanentDelete: canPermanentDelete,
                                  )
                                else
                                  ...slice.items.map(
                                    (record) => _buildMobileCard(
                                      theme,
                                      record,
                                      canRestore: canRestore,
                                      canPermanentDelete: canPermanentDelete,
                                    ),
                                  ),
                                if (slice.totalItems > 0) ...[
                                  const SizedBox(height: 12),
                                  _buildPagination(slice),
                                ],
                              ],
                            ),
                          ),
                        ),
            ),
            if (_busy)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCards(FlutterFlowTheme theme, bool wide) {
    final cards = [
      _analyticsCard(
        theme,
        tr(context, 'order.deleted.analyticsTotal'),
        '${_analytics.totalDeletedOrders}',
      ),
      _analyticsCard(
        theme,
        tr(context, 'order.deleted.analyticsRevenue'),
        '\$${_analytics.totalDeletedRevenue.toStringAsFixed(2)}',
      ),
      _analyticsCard(
        theme,
        tr(context, 'order.deleted.analyticsTopProduct'),
        _analytics.mostDeletedProduct,
      ),
      _analyticsCard(
        theme,
        tr(context, 'order.deleted.analyticsTopDeleter'),
        _analytics.mostActiveDeleter,
      ),
    ];

    if (wide) {
      return Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: card == cards.last ? 0 : 10),
                  child: card,
                ),
              ),
            )
            .toList(),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards
          .map(
            (card) => SizedBox(
              width: MediaQuery.sizeOf(context).width / 2 - 21,
              child: card,
            ),
          )
          .toList(),
    );
  }

  Widget _analyticsCard(FlutterFlowTheme theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.titleMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(FlutterFlowTheme theme, List<String> deleterOptions) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _model.searchController,
            focusNode: _model.searchFocusNode,
            decoration: InputDecoration(
              labelText: tr(context, 'order.deleted.searchHint'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => _resetPageAndRefresh(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickDate(isFrom: true),
                icon: const Icon(Icons.date_range),
                label: Text(
                  _model.deletedFrom == null
                      ? tr(context, 'order.deleted.deletedFrom')
                      : tr(context, 'order.deleted.fromDate', params: {
                          'date': formatDeletedOrderDate(_model.deletedFrom),
                        }),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickDate(isFrom: false),
                icon: const Icon(Icons.date_range),
                label: Text(
                  _model.deletedTo == null
                      ? tr(context, 'order.deleted.deletedTo')
                      : tr(context, 'order.deleted.toDate', params: {
                          'date': formatDeletedOrderDate(_model.deletedTo),
                        }),
                ),
              ),
              DropdownButton<String>(
                value: _model.deletedByFilter,
                items: [
                  DropdownMenuItem(
                    value: 'All',
                    child: Text(tr(context, 'order.deleted.deletedByAll')),
                  ),
                  ...deleterOptions.map(
                    (email) => DropdownMenuItem(value: email, child: Text(email)),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _model.deletedByFilter = value ?? 'All';
                    _model.pageIndex = 0;
                  });
                },
              ),
              DropdownButton<String>(
                value: _model.statusFilter,
                items: kDeletedOrderStatusFilterOptions
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status == 'All'
                              ? tr(context, 'order.deleted.statusAll')
                              : status,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _model.statusFilter = value ?? 'All';
                    _model.pageIndex = 0;
                  });
                },
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _model.searchController?.clear();
                    _model.deletedFrom = null;
                    _model.deletedTo = null;
                    _model.deletedByFilter = 'All';
                    _model.statusFilter = 'All';
                    _model.pageIndex = 0;
                  });
                },
                child: Text(tr(context, 'order.deleted.clearFilters')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    FlutterFlowTheme theme,
    List<DeletedOrdersRecord> records, {
    required bool canRestore,
    required bool canPermanentDelete,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(theme.alternate.withValues(alpha: 0.3)),
        columns: [
          DataColumn(label: Text(tr(context, 'order.deleted.colOrderId'))),
          DataColumn(label: Text(tr(context, 'order.deleted.colCustomer'))),
          DataColumn(label: Text(tr(context, 'order.deleted.colOrderDate'))),
          DataColumn(label: Text(tr(context, 'order.deleted.colTotal'))),
          DataColumn(label: Text(tr(context, 'order.deleted.colDeletedDate'))),
          DataColumn(label: Text(tr(context, 'order.deleted.colDeletedBy'))),
          DataColumn(label: Text(tr(context, 'order.deleted.colReason'))),
          DataColumn(label: Text(tr(context, 'order.deleted.colStatus'))),
          DataColumn(label: Text(tr(context, 'admin.userList.colActions'))),
        ],
        rows: records
            .map(
              (record) => DataRow(
                cells: [
                  DataCell(_deletedBadge(theme, record.orderId)),
                  DataCell(Text(deletedOrderCustomerName(record))),
                  DataCell(Text(formatDeletedOrderDate(deletedOrderCreatedTime(record)))),
                  DataCell(Text('\$${deletedOrderTotalAmount(record).toStringAsFixed(2)}')),
                  DataCell(Text(formatDeletedOrderDateTime(record.deletedAt))),
                  DataCell(Text(record.deletedByEmail)),
                  DataCell(Text(record.deleteReason.isEmpty ? '—' : record.deleteReason)),
                  DataCell(Text(deletedOrderStatusLabel(record))),
                  DataCell(_buildActions(
                    record,
                    compact: true,
                    canRestore: canRestore,
                    canPermanentDelete: canPermanentDelete,
                  )),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMobileCard(
    FlutterFlowTheme theme,
    DeletedOrdersRecord record, {
    required bool canRestore,
    required bool canPermanentDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _deletedBadge(theme, record.orderId)),
                Chip(
                  label: Text(
                    deletedOrderStatusLabel(record),
                    style: theme.bodySmall.override(color: theme.info),
                  ),
                  backgroundColor: theme.warning,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _detailLine(
              theme,
              tr(context, 'order.deleted.colCustomer'),
              deletedOrderCustomerName(record),
            ),
            _detailLine(
              theme,
              tr(context, 'order.deleted.colOrderDate'),
              formatDeletedOrderDate(deletedOrderCreatedTime(record)),
            ),
            _detailLine(
              theme,
              tr(context, 'order.deleted.colTotal'),
              '\$${deletedOrderTotalAmount(record).toStringAsFixed(2)}',
            ),
            _detailLine(
              theme,
              tr(context, 'order.deleted.deletedLabel'),
              formatDeletedOrderDateTime(record.deletedAt),
            ),
            _detailLine(
              theme,
              tr(context, 'order.deleted.colDeletedBy'),
              record.deletedByEmail,
            ),
            if (record.deleteReason.isNotEmpty)
              _detailLine(
                theme,
                tr(context, 'order.deleted.colReason'),
                record.deleteReason,
              ),
            const SizedBox(height: 8),
            _buildActions(
              record,
              canRestore: canRestore,
              canPermanentDelete: canPermanentDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailLine(FlutterFlowTheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: theme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _deletedBadge(FlutterFlowTheme theme, String orderId) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.error),
          ),
          child: Text(
            tr(context, 'order.deleted.badge'),
            style: theme.labelSmall.override(
              color: theme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          orderId.isNotEmpty ? orderId : '—',
          style: theme.titleSmall.override(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActions(
    DeletedOrdersRecord record, {
    bool compact = false,
    required bool canRestore,
    required bool canPermanentDelete,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FFButtonWidget(
          onPressed: () {
            final serialized = serializeParam(
              record.reference,
              ParamType.DocumentReference,
            );
            context.pushNamed(
              DeletedOrderDetailPageWidget.routeName,
              queryParameters: serialized == null
                  ? const {}
                  : {'deletedOrderRef': serialized},
              extra: <String, dynamic>{'deletedOrderRef': record.reference},
            );
          },
          text: tr(context, 'order.deleted.details'),
          options: FFButtonOptions(
            height: compact ? 32 : 36,
            padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
            color: FlutterFlowTheme.of(context).secondary,
            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                  font: GoogleFonts.interTight(),
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
            elevation: 0,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        if (canRestore)
          FFButtonWidget(
            onPressed: () => _confirmRestore(record),
            text: tr(context, 'order.deleted.restore'),
            options: FFButtonOptions(
              height: compact ? 32 : 36,
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
              color: FlutterFlowTheme.of(context).primary,
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                    font: GoogleFonts.interTight(),
                    color: FlutterFlowTheme.of(context).info,
                  ),
              elevation: 0,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        if (canPermanentDelete)
          FFButtonWidget(
            onPressed: () => _confirmPermanentDelete(record),
            text: tr(context, 'order.deleted.deleteForever'),
            options: FFButtonOptions(
              height: compact ? 32 : 36,
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
              color: FlutterFlowTheme.of(context).error,
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                    font: GoogleFonts.interTight(),
                    color: FlutterFlowTheme.of(context).info,
                  ),
              elevation: 0,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }

  Widget _buildPagination(DeletedOrdersPageSlice slice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: slice.pageIndex > 0
              ? () => setState(() => _model.pageIndex = slice.pageIndex - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          tr(context, 'order.deleted.pageInfo', params: {
            'page': '${slice.pageIndex + 1}',
            'totalPages': '${slice.totalPages}',
            'count': '${slice.totalItems}',
          }),
        ),
        IconButton(
          onPressed: slice.pageIndex < slice.totalPages - 1
              ? () => setState(() => _model.pageIndex = slice.pageIndex + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
