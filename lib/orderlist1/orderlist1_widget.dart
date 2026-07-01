import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/order_navigation_helpers.dart';
import '/auth/role_helpers.dart';
import '/components/home_nav_button.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/order_list_ui_labels.dart';
import '/backend/order_status_display.dart';
import '/backend/tenant_query_helpers.dart';
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
import '/components/bulk_assign_driver_sheet.dart';
import '/components/bulk_order_action_bar.dart';
import '/components/bulk_update_status_sheet.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentKey =
        orderListTypeChipKeyFromLabel(_model.choiceChipsValue) ??
            OrderListTypeChip.all;
    final localized = currentKey.label(context);
    if (_model.choiceChipsValue != localized) {
      _model.choiceChipsValue = localized;
    }
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
        orderType: orderListTypeFilterValue(_model.choiceChipsValue),
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
  List<OrdersRecord> _displayedFilteredOrders = const [];
  List<OrderItemRecord> _displayedAllItems = const [];

  Future<void> _bulkAssignDriver(BuildContext context) async {
    final selected = _model.checkboxCheckedItems;
    final applied = await showBulkAssignDriverSheet(
      context,
      orders: selected,
    );
    if (!applied || !mounted) {
      return;
    }
    safeSetState(() {
      for (final order in selected) {
        _model.checkboxValueMap.remove(order);
      }
      _model.filterGeneration++;
    });
  }

  Future<void> _bulkUpdateStatus(BuildContext context) async {
    final selected = _model.checkboxCheckedItems;
    final applied = await showBulkUpdateStatusSheet(
      context,
      orders: selected,
    );
    if (!applied || !mounted) {
      return;
    }
    safeSetState(() {
      for (final order in selected) {
        _model.checkboxValueMap.remove(order);
      }
      _model.filterGeneration++;
    });
  }

  Future<void> _deleteSelectedOrders(BuildContext context) async {
    if (_deletingOrders) {
      return;
    }

    final selected = _model.checkboxCheckedItems;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'order.delete.selectFirst'),
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
        title: Text(tr(context, 'order.delete.title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(
                  context,
                  'order.delete.body',
                  params: {
                    'count': '${selected.length}',
                    'preview': '$previewIds$extra',
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: tr(context, 'order.delete.reasonLabel'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
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
            child: Text(tr(context, 'common.delete')),
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
            tr(
              context,
              'order.delete.success',
              params: {'count': '$deletedCount'},
            ),
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
          content: Text(
            tr(context, 'order.delete.failed', params: {'error': '$e'}),
          ),
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
      List<OrdersRecord> filtered;
      List<OrderItemRecord> allOrderItems;

      if (_displayedFilteredOrders.isNotEmpty) {
        filtered = _displayedFilteredOrders;
        allOrderItems = _displayedAllItems;
      } else {
        final orders = await queryTenantOrdersRecordOnce(
          queryBuilder: _orderDateQuery(),
        );
        allOrderItems = await queryTenantOrderItemRecordOnce();
        filtered = _filterOrders(orders, allOrderItems);
      }
      if (filtered.isEmpty) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(context, 'order.export.noMatch'),
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
            tr(
              context,
              'order.export.success',
              params: {'count': '${filtered.length}'},
            ),
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
            content: Text(
              tr(context, 'order.export.failed', params: {'error': '$e'}),
            ),
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
            tr(context, 'order.list.title'),
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
            AppBarLanguageHomeActions(),
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
                optionLabels: orderListStatusDropdownLabels(context),
                onChanged: (val) {
                  safeSetState(() => _model.dropDownValue = val);
                  _applyFilters();
                },
                width: double.infinity,
                height: 34.0,
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
                hintText: tr(context, 'order.filter.statusHint'),
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
                margin: const EdgeInsetsDirectional.fromSTEB(10.0, 2.0, 10.0, 0.0),
                hidesUnderline: true,
                isOverButton: false,
                isSearchable: false,
                isMultiSelect: false,
              ),
              FlutterFlowChoiceChips(
                options: orderListTypeChipOptions(context),
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
                chipSpacing: 6.0,
                rowSpacing: 4.0,
                multiselect: false,
                alignment: WrapAlignment.start,
                controller: _model.choiceChipsValueController ??=
                    FormFieldController<List<String>>(
                  ['All'],
                ),
                wrapped: true,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8.0, 2.0, 8.0, 0.0),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                  FlutterFlowIconButton(
                    borderRadius: 8.0,
                    buttonSize: 34.0,
                    fillColor: FlutterFlowTheme.of(context).primary,
                    icon: Icon(
                      Icons.calendar_month,
                      color: FlutterFlowTheme.of(context).info,
                      size: 20.0,
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
                    '${tr(context, 'order.filter.dateStart')}${dateTimeFormat(
                      "d/M/y",
                      _model.datePicked1,
                      locale: FFLocalizations.of(context).languageCode,
                    )}',
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelMedium.fontStyle,
                        ),
                  ),
                  FlutterFlowIconButton(
                    borderRadius: 8.0,
                    buttonSize: 34.0,
                    fillColor: FlutterFlowTheme.of(context).primary,
                    icon: FaIcon(
                      FontAwesomeIcons.calendarDay,
                      color: FlutterFlowTheme.of(context).info,
                      size: 18.0,
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
                    '${tr(context, 'order.filter.dateEnd')}${dateTimeFormat(
                      "d/M/y",
                      _model.datePicked2,
                      locale: FFLocalizations.of(context).languageCode,
                    )}',
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelMedium.fontStyle,
                        ),
                  ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  10.0,
                  4.0,
                  10.0,
                  0.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _model.searchController,
                        focusNode: _model.searchFocusNode,
                        style: FlutterFlowTheme.of(context).bodySmall,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          hintText: tr(context, 'order.search.hint'),
                          prefixIcon: const Icon(Icons.search, size: 20),
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
                        onChanged: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    FFButtonWidget(
                      onPressed: _applyFilters,
                      text: tr(context, 'common.search'),
                      options: FFButtonOptions(
                        height: 38.0,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            10.0, 0.0, 10.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context)
                            .labelLarge
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
              if (canExportOrderCsv(AppStateNotifier.instance.userRole))
                Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 4.0),
                  child: FFButtonWidget(
                    onPressed: _exportingCsv
                        ? null
                        : () => _exportFilteredOrders(context),
                    text: _exportingCsv
                        ? tr(context, 'common.exporting')
                        : tr(context, 'common.exportCsv'),
                    icon: const Icon(
                      Icons.download_outlined,
                      size: 16.0,
                      color: Colors.white,
                    ),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 36.0,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          10.0, 0.0, 10.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle:
                          FlutterFlowTheme.of(context).labelLarge.override(
                                font: GoogleFonts.interTight(),
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
                  child: StreamBuilder<List<UsersRecord>>(
                    stream: queryUsersRecord(),
                    builder: (context, usersSnapshot) {
                      final driverLookup = orderListDriverNameLookup(
                        usersSnapshot.data ?? const [],
                      );

                      return StreamBuilder<List<OrderItemRecord>>(
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
                          '${_model.datePicked2?.millisecondsSinceEpoch}-'
                          '${_model.searchController?.text.trim()}',
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
                          _displayedFilteredOrders = listViewOrdersRecordList;
                          _displayedAllItems = allItems;

                          if (listViewOrdersRecordList.isEmpty) {
                            return Center(
                              child: Text(
                                tr(context, 'order.list.empty'),
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
                                      driverLabel: orderListAssignedDriverLabel(
                                        context,
                                        listViewOrdersRecord,
                                        driverLookup,
                                      ),
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
                  );
                    },
                  ),
                ),
              ),
              BulkOrderActionBar(
                selectedCount: _model.checkboxCheckedItems.length,
                deleting: _deletingOrders,
                onAssignDriver: () => _bulkAssignDriver(context),
                onUpdateStatus: () => _bulkUpdateStatus(context),
                onDelete: canDeleteOrders(AppStateNotifier.instance.userRole)
                    ? () => _deleteSelectedOrders(context)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
