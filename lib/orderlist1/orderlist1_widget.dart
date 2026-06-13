import '/auth/firebase_auth/auth_util.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/backend.dart';
import '/backend/order_navigation_helpers.dart';
import '/auth/role_helpers.dart';
import '/components/home_nav_button.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/order_status_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/nav/nav.dart';
import 'dart:ui';
import '/backend/csv_export_service.dart';
import '/backend/order_delete_service.dart';
import '/backend/order_list_display_helpers.dart';
import '/components/order_list_item_card.dart';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'orderlist1_model.dart';
export 'orderlist1_model.dart';

class Orderlist1Widget extends StatefulWidget {
  const Orderlist1Widget({
    super.key,
    this.initialStatus,
    this.initialOrderType,
    this.initialStartDate,
    this.initialEndDate,
    this.initialLeftoverOnly = false,
  });

  /// Status dropdown value, e.g. `pending`, `completed`, or `all`.
  final String? initialStatus;

  /// Choice chip value: `All`, `Delivery`, `Retail`, `PickUp`.
  final String? initialOrderType;

  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool initialLeftoverOnly;

  static String routeName = 'orderlist';
  static String routePath = '/orderlist';
  /// Legacy path — redirects to [routePath] in the router.
  static String legacyRoutePath = '/orderlist1';

  @override
  State<Orderlist1Widget> createState() => _Orderlist1WidgetState();
}

class _Orderlist1WidgetState extends State<Orderlist1Widget> {
  late Orderlist1Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Orderlist1Model());
    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();
    _model.dropDownValueController ??=
        FormFieldController<String>('all');
    _model.dropDownValue = 'all';

    _applyRouteFilters();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  void _applyRouteFilters() {
    var filtersApplied = false;

    if (widget.initialStatus != null && widget.initialStatus!.isNotEmpty) {
      _model.dropDownValue = widget.initialStatus;
      _model.dropDownValueController?.value = widget.initialStatus;
      filtersApplied = true;
    }
    if (widget.initialOrderType != null &&
        widget.initialOrderType!.isNotEmpty) {
      _model.choiceChipsValueController ??=
          FormFieldController<List<String>>([]);
      _model.choiceChipsValue = widget.initialOrderType;
      _model.choiceChipsValueController?.value = [widget.initialOrderType!];
      filtersApplied = true;
    }
    if (widget.initialStartDate != null) {
      _model.datePicked1 = widget.initialStartDate;
      filtersApplied = true;
    }
    if (widget.initialEndDate != null) {
      _model.datePicked2 = widget.initialEndDate;
      filtersApplied = true;
    }
    if (widget.initialLeftoverOnly) {
      _model.leftoverOnly = true;
      filtersApplied = true;
    }

    if (widget.initialStartDate == null &&
        widget.initialEndDate == null &&
        !widget.initialLeftoverOnly) {
      final range = defaultOrderListDateRange();
      _model.datePicked1 = range.start;
      _model.datePicked2 = range.end;
      filtersApplied = true;
    }

    if (filtersApplied) {
      _model.filterGeneration++;
    }
  }

  @override
  void dispose() {
    _model.searchController?.dispose();
    _model.searchFocusNode?.dispose();
    _model.dispose();

    super.dispose();
  }

  void _applyFilters() {
    safeSetState(() => _model.filterGeneration++);
  }

  Query Function(Query) _orderDateQuery() => buildOrderListFirestoreQuery(
        startDate: _model.datePicked1,
        endDate: _model.datePicked2,
      );

  List<OrdersRecord> _filterOrders(
    List<OrdersRecord> orders,
    List<OrderItemRecord> items,
  ) =>
      applyOrderListClientFilters(
        orders: orders,
        orderItems: items,
        legacyStatus: _model.dropDownValue,
        orderType: _model.choiceChipsValue,
        startDate: _model.datePicked1,
        endDate: _model.datePicked2,
        searchText: _model.searchController?.text ?? '',
        leftoverOnly: _model.leftoverOnly,
      );

  bool? _selectAllValue(List<OrdersRecord> orders) {
    if (orders.isEmpty) {
      return false;
    }
    final selectedCount =
        orders.where((order) => _model.checkboxValueMap[order] == true).length;
    if (selectedCount == 0) {
      return false;
    }
    if (selectedCount == orders.length) {
      return true;
    }
    return null;
  }

  void _toggleSelectAll(List<OrdersRecord> orders, bool? value) {
    safeSetState(() {
      final selectAll = value == true;
      for (final order in orders) {
        if (selectAll) {
          _model.checkboxValueMap[order] = true;
        } else {
          _model.checkboxValueMap.remove(order);
        }
      }
    });
  }

  bool _exportingCsv = false;
  bool _deletingOrders = false;

  Future<void> _deleteSelectedOrders(BuildContext context) async {
    if (_deletingOrders) {
      return;
    }

    final selected = _model.checkboxCheckedItems;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select one or more orders to delete.',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          backgroundColor: FlutterFlowTheme.of(context).secondary,
        ),
      );
      return;
    }

    final previewIds = selected
        .map((o) => o.orderId.isNotEmpty ? o.orderId : o.reference.id)
        .take(5)
        .join(', ');
    final extra = selected.length > 5 ? '…' : '';

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete selected orders?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Delete ${selected.length} order(s)?\n\n'
                'They will be archived to deleted_orders for audit and removed '
                'from the order list.\n\n$previewIds$extra',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Delete reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: FlutterFlowTheme.of(context).error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    final deleteReason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _deletingOrders = true);
    try {
      final allItems = await queryTenantOrderItemRecordOnce();
      final deletedCount = await archiveAndDeleteOrders(
        orders: selected,
        allItems: allItems,
        deleteReason: deleteReason.isEmpty ? null : deleteReason,
      );
      if (!mounted) {
        return;
      }
      safeSetState(() {
        for (final order in selected) {
          _model.checkboxValueMap.remove(order);
        }
        _model.filterGeneration++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deleted $deletedCount order(s). Archived to deleted_orders.',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          backgroundColor: FlutterFlowTheme.of(context).secondary,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingOrders = false);
      }
    }
  }

  Future<void> _exportFilteredOrders(BuildContext context) async {
    if (_exportingCsv) {
      return;
    }
    setState(() => _exportingCsv = true);
    try {
      final orders = await queryTenantOrdersRecordOnce(
        queryBuilder: _orderDateQuery(),
      );
      final allOrderItems = await queryTenantOrderItemRecordOnce();
      final filtered = _filterOrders(orders, allOrderItems);
      if (filtered.isEmpty) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No orders match the current filters.',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).primaryText,
              ),
            ),
            backgroundColor: FlutterFlowTheme.of(context).secondary,
          ),
        );
        return;
      }
      final startLabel = _model.datePicked1 != null
          ? dateTimeFormat(
              'yMd',
              _model.datePicked1,
              locale: FFLocalizations.of(context).languageCode,
            )
          : 'all';
      final endLabel = _model.datePicked2 != null
          ? dateTimeFormat(
              'yMd',
              _model.datePicked2,
              locale: FFLocalizations.of(context).languageCode,
            )
          : 'all';
      await downloadOrdersCsv(
        context: context,
        orders: filtered,
        allOrderItems: allOrderItems,
        filenameBase: 'OrderList_${startLabel}_$endLabel',
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${filtered.length} order(s). Check Downloads or Files app.',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: FlutterFlowTheme.of(context).secondary,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exportingCsv = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Order List',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: const [
            HomeNavIconButton.onPrimary(),
          ],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              FlutterFlowDropDown<String>(
                controller: _model.dropDownValueController ??=
                    FormFieldController<String>('all'),
                options: ['all', ...kOrderListLegacyStatusOptions],
                onChanged: (val) {
                  safeSetState(() => _model.dropDownValue = val);
                  _applyFilters();
                },
                width: double.infinity,
                height: 40.0,
                textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                hintText: 'Status (all)',
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 24.0,
                ),
                fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                elevation: 2.0,
                borderColor: Colors.transparent,
                borderWidth: 0.0,
                borderRadius: 8.0,
                margin: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                hidesUnderline: true,
                isOverButton: false,
                isSearchable: false,
                isMultiSelect: false,
              ),
              FlutterFlowChoiceChips(
                options: [
                  ChipData('All'),
                  ChipData('Retail'),
                  ChipData('Delivery'),
                  ChipData('PickUp'),
                ],
                onChanged: (val) {
                  safeSetState(
                      () => _model.choiceChipsValue = val?.firstOrNull);
                  _applyFilters();
                },
                selectedChipStyle: ChipStyle(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).info,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                  iconColor: FlutterFlowTheme.of(context).info,
                  iconSize: 16.0,
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                unselectedChipStyle: ChipStyle(
                  backgroundColor:
                      FlutterFlowTheme.of(context).secondaryBackground,
                  textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                  iconColor: FlutterFlowTheme.of(context).secondaryText,
                  iconSize: 16.0,
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                chipSpacing: 8.0,
                rowSpacing: 8.0,
                multiselect: false,
                alignment: WrapAlignment.start,
                controller: _model.choiceChipsValueController ??=
                    FormFieldController<List<String>>(
                  ['All'],
                ),
                wrapped: true,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FlutterFlowIconButton(
                    borderRadius: 8.0,
                    buttonSize: 40.0,
                    fillColor: FlutterFlowTheme.of(context).primary,
                    icon: Icon(
                      Icons.calendar_month,
                      color: FlutterFlowTheme.of(context).info,
                      size: 24.0,
                    ),
                    onPressed: () async {
                      final _datePicked1Date = await showDatePicker(
                        context: context,
                        initialDate: getCurrentTimestamp,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2050),
                        builder: (context, child) {
                          return wrapInMaterialDatePickerTheme(
                            context,
                            child!,
                            headerBackgroundColor:
                                FlutterFlowTheme.of(context).primary,
                            headerForegroundColor:
                                FlutterFlowTheme.of(context).info,
                            headerTextStyle: FlutterFlowTheme.of(context)
                                .headlineLarge
                                .override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineLarge
                                        .fontStyle,
                                  ),
                                  fontSize: 32.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .fontStyle,
                                ),
                            pickerBackgroundColor: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            pickerForegroundColor:
                                FlutterFlowTheme.of(context).primaryText,
                            selectedDateTimeBackgroundColor:
                                FlutterFlowTheme.of(context).primary,
                            selectedDateTimeForegroundColor:
                                FlutterFlowTheme.of(context).info,
                            actionButtonForegroundColor:
                                FlutterFlowTheme.of(context).primaryText,
                            iconSize: 24.0,
                          );
                        },
                      );

                      if (_datePicked1Date != null) {
                        safeSetState(() {
                          _model.datePicked1 = DateTime(
                            _datePicked1Date.year,
                            _datePicked1Date.month,
                            _datePicked1Date.day,
                          );
                        });
                        _applyFilters();
                      }
                    },
                  ),
                  Text(
                    'Start:${dateTimeFormat(
                      "d/M/y",
                      _model.datePicked1,
                      locale: FFLocalizations.of(context).languageCode,
                    )}',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  FlutterFlowIconButton(
                    borderRadius: 8.0,
                    buttonSize: 40.0,
                    fillColor: FlutterFlowTheme.of(context).primary,
                    icon: FaIcon(
                      FontAwesomeIcons.calendarDay,
                      color: FlutterFlowTheme.of(context).info,
                      size: 24.0,
                    ),
                    onPressed: () async {
                      final _datePicked2Date = await showDatePicker(
                        context: context,
                        initialDate: getCurrentTimestamp,
                        firstDate: getCurrentTimestamp,
                        lastDate: DateTime(2050),
                        builder: (context, child) {
                          return wrapInMaterialDatePickerTheme(
                            context,
                            child!,
                            headerBackgroundColor:
                                FlutterFlowTheme.of(context).primary,
                            headerForegroundColor:
                                FlutterFlowTheme.of(context).info,
                            headerTextStyle: FlutterFlowTheme.of(context)
                                .headlineLarge
                                .override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineLarge
                                        .fontStyle,
                                  ),
                                  fontSize: 32.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .fontStyle,
                                ),
                            pickerBackgroundColor: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            pickerForegroundColor:
                                FlutterFlowTheme.of(context).primaryText,
                            selectedDateTimeBackgroundColor:
                                FlutterFlowTheme.of(context).primary,
                            selectedDateTimeForegroundColor:
                                FlutterFlowTheme.of(context).info,
                            actionButtonForegroundColor:
                                FlutterFlowTheme.of(context).primaryText,
                            iconSize: 24.0,
                          );
                        },
                      );

                      if (_datePicked2Date != null) {
                        safeSetState(() {
                          _model.datePicked2 = DateTime(
                            _datePicked2Date.year,
                            _datePicked2Date.month,
                            _datePicked2Date.day,
                          );
                        });
                        _applyFilters();
                      }
                    },
                  ),
                  Text(
                    'End:${dateTimeFormat(
                      "d/M/y",
                      _model.datePicked2,
                      locale: FFLocalizations.of(context).languageCode,
                    )}',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12.0, 8.0, 12.0, 0.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _model.searchController,
                        focusNode: _model.searchFocusNode,
                        decoration: InputDecoration(
                          hintText:
                              'Search name, address, product, order ID...',
                          prefixIcon: const Icon(Icons.search),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          filled: true,
                          fillColor: FlutterFlowTheme.of(context)
                              .secondaryBackground,
                        ),
                        onFieldSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    FFButtonWidget(
                      onPressed: _applyFilters,
                      text: 'Search',
                      options: FFButtonOptions(
                        height: 48.0,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            12.0, 0.0, 12.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context)
                            .titleSmall
                            .override(
                              font: GoogleFonts.interTight(
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                              color: Colors.white,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .fontStyle,
                            ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                ),
              ),
              if (canExportOrderCsv(AppStateNotifier.instance.userRole))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: FFButtonWidget(
                    onPressed: _exportingCsv
                        ? null
                        : () => _exportFilteredOrders(context),
                    text: _exportingCsv ? 'Exporting...' : 'Export CSV',
                    icon: const Icon(
                      Icons.download_outlined,
                      size: 18.0,
                      color: Colors.white,
                    ),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 44.0,
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.interTight(),
                                color: Colors.white,
                              ),
                    ),
                  ),
                ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  child: StreamBuilder<List<OrderItemRecord>>(
                    key: ValueKey('items-${_model.filterGeneration}'),
                    stream: queryTenantOrderItemRecord(),
                    builder: (context, itemsSnapshot) {
                      if (!itemsSnapshot.hasData) {
                        return Center(
                          child: SizedBox(
                            width: 50.0,
                            height: 50.0,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                FlutterFlowTheme.of(context).primary,
                              ),
                            ),
                          ),
                        );
                      }
                      final allItems = itemsSnapshot.data!;

                      return StreamBuilder<List<OrdersRecord>>(
                        key: ValueKey(
                          'orders-${_model.filterGeneration}-'
                          '${_model.datePicked1?.millisecondsSinceEpoch}-'
                          '${_model.datePicked2?.millisecondsSinceEpoch}',
                        ),
                        stream: queryTenantOrdersRecord(
                          queryBuilder: _orderDateQuery(),
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: SizedBox(
                                width: 50.0,
                                height: 50.0,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    FlutterFlowTheme.of(context).primary,
                                  ),
                                ),
                              ),
                            );
                          }
                          final listViewOrdersRecordList = _filterOrders(
                            snapshot.data!,
                            allItems,
                          );

                          if (listViewOrdersRecordList.isEmpty) {
                            return Center(
                              child: Text(
                                'No orders match your filters.',
                                style: FlutterFlowTheme.of(context).bodyLarge,
                              ),
                            );
                          }

                          return Column(
                            children: [
                              OrderListTableHeader(
                                selectAllValue:
                                    _selectAllValue(listViewOrdersRecordList),
                                onSelectAllChanged: (value) => _toggleSelectAll(
                                  listViewOrdersRecordList,
                                  value,
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: listViewOrdersRecordList.length,
                                  itemBuilder: (context, listViewIndex) {
                                    final listViewOrdersRecord =
                                        listViewOrdersRecordList[listViewIndex];
                                    final orderItems =
                                        orderListItemsForOrder(
                                      allItems,
                                      listViewOrdersRecord,
                                    );
                                    return OrderListItemCard(
                                      order: listViewOrdersRecord,
                                      items: orderItems,
                                      locale: FFLocalizations.of(context)
                                          .languageCode,
                                      checked: _model.checkboxValueMap[
                                              listViewOrdersRecord] ??
                                          false,
                                      onCheckedChanged: (newValue) {
                                        safeSetState(() {
                                          _model.checkboxValueMap[
                                                  listViewOrdersRecord] =
                                              newValue ?? false;
                                        });
                                      },
                                      onTap: () {
                                        openOrderDetail(
                                          context,
                                          listViewOrdersRecord.reference,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    FFButtonWidget(
                      onPressed: () async {
                        for (int loop1Index = 0;
                            loop1Index < _model.checkboxCheckedItems.length;
                            loop1Index++) {
                          final currentLoop1Item =
                              _model.checkboxCheckedItems[loop1Index];

                          await updateOrderStatus(
                            currentLoop1Item.reference,
                            OrderStatus.processing,
                          );
                          await auditLogOrderStatusChangeByRef(
                            currentLoop1Item.reference,
                            OrderStatus.processing,
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'processing',
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                            ),
                            duration: Duration(milliseconds: 4000),
                            backgroundColor:
                                FlutterFlowTheme.of(context).secondary,
                          ),
                        );
                      },
                      text: 'Start Processing',
                      options: FFButtonOptions(
                        height: 40.0,
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    FFButtonWidget(
                      onPressed: () async {
                        for (int loop1Index = 0;
                            loop1Index < _model.checkboxCheckedItems.length;
                            loop1Index++) {
                          final currentLoop1Item =
                              _model.checkboxCheckedItems[loop1Index];

                          await updateOrderStatus(
                            currentLoop1Item.reference,
                            OrderStatus.ready_to_delivery,
                          );
                          await auditLogOrderStatusChangeByRef(
                            currentLoop1Item.reference,
                            OrderStatus.ready_to_delivery,
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Ready to Ship',
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                            ),
                            duration: Duration(milliseconds: 4000),
                            backgroundColor:
                                FlutterFlowTheme.of(context).secondary,
                          ),
                        );
                      },
                      text: 'Ready to Ship',
                      options: FFButtonOptions(
                        height: 40.0,
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).secondary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    if (canDeleteOrders(AppStateNotifier.instance.userRole))
                      FFButtonWidget(
                        onPressed: _deletingOrders
                            ? null
                            : () => _deleteSelectedOrders(context),
                        text: _deletingOrders ? 'Deleting...' : 'Delete',
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18.0,
                          color: Colors.white,
                        ),
                        options: FFButtonOptions(
                          height: 40.0,
                          padding: EdgeInsetsDirectional.fromSTEB(
                              12.0, 0.0, 12.0, 0.0),
                          iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 4.0, 0.0),
                          color: FlutterFlowTheme.of(context).error,
                          textStyle: FlutterFlowTheme.of(context)
                              .titleSmall
                              .override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FontWeight.w600,
                                ),
                                color: Colors.white,
                                letterSpacing: 0.0,
                              ),
                          elevation: 0.0,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
