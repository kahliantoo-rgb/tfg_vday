import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/driver_assignment_helpers.dart';
import '/backend/driver_delivery_filter_helpers.dart';
import '/backend/driver_delivery_tab_labels.dart';
import '/backend/daily_sales_report_service.dart';
import '/backend/driver_route_helpers.dart';
import '/backend/order_status_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import '/backend/order_list_display_helpers.dart';
import '/components/driver_suggested_route_section.dart';
import '/components/staff_notice_app_bar_button.dart';
import '/components/driver_delivery_order_card.dart';
import '/components/home_nav_button.dart';
import '/components/language_picker_button.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/services/google_maps_service.dart';
import '/l10n/locale_text.dart';
import '/l10n/tr.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'driver_delivery_page_model.dart';
export 'driver_delivery_page_model.dart';

/// Create a FlutterFlow page named "DriverDeliveryPage" for delivery drivers.
///
/// Purpose:
/// Allow drivers to view, accept, and update delivery orders assigned to
/// them.
///
/// Layout:
/// - AppBar with title "My Deliveries"
/// - Clean, mobile-first layout
/// - Light background, clear spacing
///
/// Content:
/// 1) Filter tabs or chips:
///    - Assigned
///    - Out for Delivery
///    - Completed
///
/// 2) ListView of delivery orders (from Firestore "orders" collection)
///    - Query orders where:
///      - assigned_driver == current authenticated user
///      - order_status in [ready_to_ship, out_for_delivery, completed]
///    - Order by delivery_date ascending
///
/// Each order card shows:
/// - Order Number
/// - Customer Name
/// - Delivery Address
/// - Delivery Time Slot
/// - Current Order Status (badge)
///
/// Actions per order:
/// - If status == ready_to_ship:
///   - Button: "Start Delivery"
///   - Update order_status to out_for_delivery
/// - If status == out_for_delivery:
///   - Button: "Mark as Delivered"
///   - Update order_status to completed
/// - Disable buttons if status == completed
class DriverDeliveryPageWidget extends StatefulWidget {
  const DriverDeliveryPageWidget({super.key});

  static String routeName = 'DriverDeliveryPage';
  static String routePath = '/driverDeliveryPage';

  @override
  State<DriverDeliveryPageWidget> createState() =>
      _DriverDeliveryPageWidgetState();
}

class _DriverDeliveryPageWidgetState extends State<DriverDeliveryPageWidget> {
  late DriverDeliveryPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  DocumentReference? _driverRef;
  bool _profileLoading = true;
  OrderStatus? _tabStatus;
  final _dateLabel = DateFormat('d/M/y');

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DriverDeliveryPageModel());
    _model.filterStartDate = calendarDay(DateTime.now());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        _driverRef = profile?.reference;
        await TenantContext.instance.initialize(profile);
        AppStateNotifier.instance.syncUserRole(profile?.role);
      }
      if (mounted) {
        safeSetState(() => _profileLoading = false);
      }
    });
  }

  Query Function(Query) _orderQuery() {
    if (_driverRef == null) {
      return (Query query) => query;
    }
    return (Query query) =>
        query.where('assigned_driver', isEqualTo: _driverRef);
  }

  void _onTabChipChanged(String? chip) {
    safeSetState(() {
      _model.choiceChipsValue = chip;
      _tabStatus = driverTabStatusFromChip(chip);
    });
  }

  Future<void> _pickFilterDate({required bool isStart}) async {
    final today = calendarDay(DateTime.now());
    final initial = calendarDay(
      (isStart ? _model.filterStartDate : _model.filterEndDate) ?? today,
    );
    final startAnchor = calendarDay(_model.filterStartDate ?? today);
    final firstDate = isStart
        ? today
        : (startAnchor.isBefore(today) ? today : startAnchor);
    final picked = await showDatePicker(
      context: context,
      helpText: isStart
          ? tr(context, 'order.driver.filterFromDate')
          : tr(context, 'order.driver.filterToDate'),
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 1, 12, 31),
    );
    if (picked == null) {
      return;
    }
    safeSetState(() {
      var day = calendarDay(picked);
      if (day.isBefore(today)) {
        day = today;
      }
      if (isStart) {
        _model.filterStartDate = day;
        if (_model.filterEndDate != null &&
            _model.filterEndDate!.isBefore(day)) {
          _model.filterEndDate = day;
        }
      } else {
        _model.filterEndDate = day;
        if (_model.filterStartDate != null &&
            _model.filterStartDate!.isAfter(day)) {
          _model.filterStartDate = day;
        }
      }
    });
  }

  void _resetDateFilterToToday() {
    safeSetState(() {
      _model.filterStartDate = calendarDay(DateTime.now());
      _model.filterEndDate = null;
    });
  }

  String _dateFilterSummary(BuildContext context) {
    final start = _model.filterStartDate ?? calendarDay(DateTime.now());
    final end = _model.filterEndDate;
    if (end == null) {
      if (calendarDay(start) == calendarDay(DateTime.now())) {
        return tr(context, 'order.driver.fromTodayOnwards');
      }
      return tr(context, 'order.driver.dateFrom',
          params: {'date': _dateLabel.format(start)});
    }
    if (calendarDay(start) == calendarDay(end)) {
      return _dateLabel.format(start);
    }
    return '${_dateLabel.format(start)} – ${_dateLabel.format(end)}';
  }

  void _syncStatusFilterChips(BuildContext context) {
    final defaultLabel = DriverDeliveryTabKey.all.label(context);
    _model.choiceChipsValueController ??=
        FormFieldController<List<String>>([defaultLabel]);
    final key = driverDeliveryTabKeyFromLabel(_model.choiceChipsValue);
    if (key == null) {
      _model.choiceChipsValue = defaultLabel;
      _model.choiceChipsValueController!.value = [defaultLabel];
      _tabStatus = null;
    } else {
      _tabStatus = driverTabStatusFromChip(_model.choiceChipsValue);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentKey =
        driverDeliveryTabKeyFromLabel(_model.choiceChipsValue) ??
            DriverDeliveryTabKey.all;
    final localized = currentKey.label(context);
    if (_model.choiceChipsValue != localized) {
      _model.choiceChipsValue = localized;
      _model.choiceChipsValueController?.value = [localized];
    }
    _tabStatus = driverTabStatusFromChip(_model.choiceChipsValue);
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _logout() async {
    await authManager.signOut();
    AppStateNotifier.instance.clearUserRole();
    if (!mounted) {
      return;
    }
    context.go(LoginPageWidget.routePath);
  }

  Future<void> _openSuggestedRoute(List<OrdersRecord> orders) async {
    var addresses = driverRouteAddresses(orders);
    final totalStops = addresses.length;
    if (totalStops == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'order.driver.noRouteAddresses')),
        ),
      );
      return;
    }

    addresses = limitRouteStops(addresses);
    if (totalStops > kDriverRouteMaxStops && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'order.driver.routeLimited',
                params: {'count': '$kDriverRouteMaxStops'}),
          ),
        ),
      );
    }

    final opened = await GoogleMapsService.openMultiStopRoute(addresses);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'order.driver.mapsOpenFailed')),
        ),
      );
    }
  }

  bool _showSuggestedRoute(List<OrdersRecord> orders) {
    return driverRouteAddresses(orders).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    _syncStatusFilterChips(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            loc(
              context,
              en: 'My Deliveries',
              zh: '我的派送',
              ms: 'Penghantaran Saya',
            ),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [
            const StaffNoticeAppBarButton(),
            const LanguagePickerButton(),
            const HomeNavIconButton(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
              child: FlutterFlowIconButton(
                borderRadius: 20.0,
                buttonSize: 40.0,
                icon: Icon(
                  Icons.logout,
                  color: FlutterFlowTheme.of(context).primaryText,
                  size: 24.0,
                ),
                onPressed: () async => _logout(),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
              child: FlutterFlowIconButton(
                borderRadius: 20.0,
                buttonSize: 40.0,
                icon: Icon(
                  Icons.refresh,
                  color: FlutterFlowTheme.of(context).primaryText,
                  size: 24.0,
                ),
                onPressed: () => safeSetState(() {}),
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: ListView(
            padding: EdgeInsets.zero,
            primary: false,
            scrollDirection: Axis.vertical,
            children: [
              ListView(
                padding: EdgeInsets.zero,
                primary: false,
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text(
                          loc(
                            context,
                            en: 'All orders assigned to you',
                            zh: '所有指派给你的订单',
                            ms: 'Semua pesanan ditugaskan kepada anda',
                          ),
                          style: FlutterFlowTheme.of(context).labelMedium.override(
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _buildDateFilter(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _profileLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _driverRef == null
                                ? Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      loc(
                                        context,
                                        en:
                                            'Could not load your driver profile. Try logging out and in again.',
                                        zh: '无法加载司机资料，请重新登录。',
                                        ms:
                                            'Profil pemandu tidak dapat dimuatkan. Sila log masuk semula.',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                          ),
                                    ),
                                  )
                                : StreamBuilder<List<OrderItemRecord>>(
                                    stream: queryTenantOrderItemRecord(),
                                    builder: (context, itemsSnapshot) {
                                      if (!itemsSnapshot.hasData) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(24),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      final allItems = itemsSnapshot.data!;

                                      return StreamBuilder<List<OrdersRecord>>(
                                        key: ValueKey(
                                          'driver-orders-${_tabStatus?.name ?? 'all'}-'
                                          '${_driverRef!.path}-'
                                          '${_model.filterStartDate?.millisecondsSinceEpoch}-'
                                          '${_model.filterEndDate?.millisecondsSinceEpoch}',
                                        ),
                                        stream: queryTenantOrdersRecord(
                                          queryBuilder: _orderQuery(),
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Text(
                                                tr(
                                                  context,
                                                  'order.driver.loadOrdersFailed',
                                                  params: {
                                                    'error': '${snapshot.error}',
                                                  },
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .error,
                                                    ),
                                              ),
                                            );
                                          }
                                          if (!snapshot.hasData) {
                                            return const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(24),
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          }

                                          final routeOrders =
                                              suggestedRouteOrders(
                                            driverActiveRouteOrders(
                                              snapshot.data!,
                                              driverRef: _driverRef,
                                              filterStart:
                                                  _model.filterStartDate,
                                              filterEnd: _model.filterEndDate,
                                            ),
                                          );

                                          final listViewOrdersRecordList =
                                              filterDriverDeliveryOrders(
                                            snapshot.data!,
                                            driverRef: _driverRef,
                                            tabStatus: _tabStatus,
                                            filterStart:
                                                _model.filterStartDate,
                                            filterEnd: _model.filterEndDate,
                                          );

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              if (_showSuggestedRoute(
                                                  routeOrders))
                                                DriverSuggestedRouteSection(
                                                  routeOrders: routeOrders,
                                                  locale: FFLocalizations.of(
                                                          context)
                                                      .languageCode,
                                                  onOpenMaps: () =>
                                                      _openSuggestedRoute(
                                                          routeOrders),
                                                ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        top: 4),
                                                child:
                                                    FlutterFlowChoiceChips(
                                                  options:
                                                      driverDeliveryTabChipOptions(
                                                          context),
                                                  onChanged: (val) =>
                                                      _onTabChipChanged(
                                                          val?.firstOrNull),
                                                  selectedChipStyle: ChipStyle(
                                                    backgroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                    textStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .override(
                                                              font: GoogleFonts
                                                                  .interTight(
                                                                fontWeight:
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleSmall
                                                                        .fontWeight,
                                                                fontStyle:
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleSmall
                                                                        .fontStyle,
                                                              ),
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontWeight,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontStyle,
                                                            ),
                                                    iconColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primaryBackground,
                                                    iconSize: 18.0,
                                                    labelPadding:
                                                        const EdgeInsetsDirectional
                                                            .fromSTEB(
                                                            16.0, 8.0, 16.0, 8.0),
                                                    elevation: 0.0,
                                                    borderColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                    borderWidth: 1.0,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                  ),
                                                  unselectedChipStyle:
                                                      ChipStyle(
                                                    backgroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .secondaryBackground,
                                                    textStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .override(
                                                              font: GoogleFonts
                                                                  .interTight(
                                                                fontWeight:
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleSmall
                                                                        .fontWeight,
                                                                fontStyle:
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleSmall
                                                                        .fontStyle,
                                                              ),
                                                              color:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontWeight,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontStyle,
                                                            ),
                                                    iconColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .secondaryText,
                                                    iconSize: 18.0,
                                                    labelPadding:
                                                        const EdgeInsetsDirectional
                                                            .fromSTEB(
                                                            16.0, 8.0, 16.0, 8.0),
                                                    elevation: 0.0,
                                                    borderColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .alternate,
                                                    borderWidth: 1.0,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                  ),
                                                  chipSpacing: 12.0,
                                                  rowSpacing: 8.0,
                                                  multiselect: false,
                                                  alignment:
                                                      WrapAlignment.center,
                                                  controller: _model
                                                      .choiceChipsValueController!,
                                                  wrapped: false,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              if (listViewOrdersRecordList
                                                  .isEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(24),
                                                  child: Text(
                                                    tr(context,
                                                        'order.driver.noOrdersForFilters'),
                                                    textAlign: TextAlign.center,
                                                    style:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .override(
                                                              color:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                            ),
                                                  ),
                                                )
                                              else
                                                ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemCount:
                                                      listViewOrdersRecordList
                                                          .length,
                                                  itemBuilder: (context,
                                                      listViewIndex) {
                                                    final order =
                                                        listViewOrdersRecordList[
                                                            listViewIndex];
                                                    final items =
                                                        orderListItemsForOrder(
                                                      allItems,
                                                      order,
                                                    );
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 16),
                                                      child:
                                                          DriverDeliveryOrderCard(
                                                        order: order,
                                                        items: items,
                                                        locale:
                                                            FFLocalizations.of(
                                                                    context)
                                                                .languageCode,
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 32.0),
                child: FFButtonWidget(
                  onPressed: () async => _logout(),
                  text: 'Logout',
                  icon: const Icon(
                    Icons.logout,
                    size: 20.0,
                  ),
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 48.0,
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final today = calendarDay(DateTime.now());
    final startDate = _model.filterStartDate ?? today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(context, 'order.driver.deliveryDateLabel'),
          style: theme.labelMedium.override(color: theme.secondaryText),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _dateFilterTile(
                context,
                label: tr(context, 'order.driver.dateFromLabel'),
                value: _dateLabel.format(startDate),
                onTap: () => _pickFilterDate(isStart: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dateFilterTile(
                context,
                label: tr(context, 'order.driver.dateToLabel'),
                value: _model.filterEndDate == null
                    ? tr(context, 'order.driver.dateOnwards')
                    : _dateLabel.format(_model.filterEndDate!),
                onTap: () => _pickFilterDate(isStart: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _dateFilterSummary(context),
                style: theme.bodySmall.override(color: theme.secondaryText),
              ),
            ),
            TextButton(
              onPressed: _resetDateFilterToToday,
              child: Text(tr(context, 'order.driver.resetToToday')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateFilterTile(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.labelSmall.override(color: theme.secondaryText),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: theme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value,
                      style: theme.titleSmall.override(
                        font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
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
}
