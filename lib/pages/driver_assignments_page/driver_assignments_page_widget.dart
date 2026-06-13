import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/backend.dart';
import '/backend/daily_sales_report_service.dart';
import '/backend/driver_assignment_helpers.dart';
import '/backend/driver_delivery_filter_helpers.dart';
import '/backend/driver_route_helpers.dart';
import '/backend/order_list_display_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/components/driver_delivery_order_card.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/services/google_maps_service.dart';
import 'driver_assignments_page_model.dart';
export 'driver_assignments_page_model.dart';

class DriverAssignmentsPageWidget extends StatefulWidget {
  const DriverAssignmentsPageWidget({super.key});

  static String routeName = 'DriverAssignmentsPage';
  static String routePath = '/driverAssignmentsPage';

  @override
  State<DriverAssignmentsPageWidget> createState() =>
      _DriverAssignmentsPageWidgetState();
}

class _DriverAssignmentsPageWidgetState
    extends State<DriverAssignmentsPageWidget> {
  late DriverAssignmentsPageModel _model;
  final _dateLabel = DateFormat('d/M/y');

  List<UsersRecord> _drivers = [];
  DocumentReference? _selectedDriverRef;
  bool _loadingDrivers = true;
  String? _driverLoadError;
  OrderStatus? _tabStatus;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DriverAssignmentsPageModel());
    _model.choiceChipsValueController ??=
        FormFieldController<List<String>>(['All']);
    final today = calendarDay(DateTime.now());
    _model.filterStartDate = today;
    _model.filterEndDate = today;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      await _loadDrivers();
    });
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _loadingDrivers = true;
      _driverLoadError = null;
    });
    try {
      final drivers = await queryTenantDriversOnce();
      if (!mounted) {
        return;
      }
      setState(() {
        _drivers = drivers;
        _selectedDriverRef =
            drivers.isNotEmpty ? drivers.first.reference : null;
        _loadingDrivers = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _driverLoadError = error.toString();
        _loadingDrivers = false;
      });
    }
  }

  Query Function(Query) _orderQuery() {
    if (_selectedDriverRef == null) {
      return (Query query) => query;
    }
    return (Query query) =>
        query.where('assigned_driver', isEqualTo: _selectedDriverRef);
  }

  void _onTabChipChanged(String? chip) {
    setState(() {
      _model.choiceChipsValue = chip;
      _tabStatus = driverTabStatusFromChip(chip);
    });
  }

  Future<void> _pickFilterDate({required bool isStart}) async {
    final today = calendarDay(DateTime.now());
    final initial = calendarDay(
      (isStart ? _model.filterStartDate : _model.filterEndDate) ?? today,
    );
    final picked = await showDatePicker(
      context: context,
      helpText: isStart ? 'Filter from date' : 'Filter to date',
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 1, 12, 31),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      final day = calendarDay(picked);
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

  void _clearDateFilter() {
    setState(() {
      _model.filterStartDate = null;
      _model.filterEndDate = null;
    });
  }

  String _dateFilterSummary() {
    final start = _model.filterStartDate;
    final end = _model.filterEndDate;
    if (start == null && end == null) {
      return 'All delivery dates';
    }
    if (start != null && end != null) {
      if (calendarDay(start) == calendarDay(end)) {
        return _dateLabel.format(start);
      }
      return '${_dateLabel.format(start)} – ${_dateLabel.format(end)}';
    }
    if (start != null) {
      return 'From ${_dateLabel.format(start)}';
    }
    return 'Until ${_dateLabel.format(end!)}';
  }

  Future<void> _openSuggestedRoute(List<OrdersRecord> orders) async {
    var addresses = driverRouteAddresses(orders);
    final totalStops = addresses.length;
    if (totalStops == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No delivery addresses to route.')),
      );
      return;
    }

    addresses = limitRouteStops(addresses);
    if (totalStops > kDriverRouteMaxStops && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening first $kDriverRouteMaxStops stops in Google Maps.',
          ),
        ),
      );
    }

    final opened = await GoogleMapsService.openMultiStopRoute(addresses);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  bool _showSuggestedRoute(List<OrdersRecord> orders) {
    if (_tabStatus == OrderStatus.completed) {
      return false;
    }
    return driverRouteAddresses(orders).length >= 1;
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canView = canAssignDriver(currentViewerRole());

    if (!canView) {
      return Scaffold(
        appBar: AppBar(
          leading: FlutterFlowIconButton(
            borderRadius: 30,
            buttonSize: 60,
            icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText),
            onPressed: () => context.safePop(),
          ),
          title: const Text('Driver Assignments'),
        ),
        body: const Center(
          child: Text('You do not have permission to view driver assignments.'),
        ),
      );
    }

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
            borderRadius: 30,
            buttonSize: 60,
            icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText),
            onPressed: () => context.safePop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver Assignments',
                style: theme.headlineMedium.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                  fontSize: 22,
                ),
              ),
              Text(
                '司机派单',
                style: theme.labelSmall.override(color: theme.secondaryText),
              ),
            ],
          ),
          actions: const [HomeNavIconButton()],
          elevation: 0,
        ),
        body: SafeArea(
          child: _loadingDrivers
              ? const Center(child: CircularProgressIndicator())
              : _driverLoadError != null
                  ? _buildDriverLoadError(theme)
                  : _drivers.isEmpty
                      ? _buildNoDrivers(theme)
                      : _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildDriverLoadError(FlutterFlowTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_driverLoadError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadDrivers,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDrivers(FlutterFlowTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No active drivers found for this company.',
          textAlign: TextAlign.center,
          style: theme.bodyMedium.override(color: theme.secondaryText),
        ),
      ),
    );
  }

  Widget _buildContent(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDriverSelector(theme),
          const SizedBox(height: 16),
          _buildDateFilter(theme),
          const SizedBox(height: 12),
          _buildStatusChips(theme),
          const SizedBox(height: 16),
          _buildOrdersSection(theme),
        ],
      ),
    );
  }

  Widget _buildDriverSelector(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DocumentReference>(
          isExpanded: true,
          value: _selectedDriverRef,
          items: [
            for (final driver in _drivers)
              DropdownMenuItem(
                value: driver.reference,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      driverDisplayName(driver),
                      style: theme.bodyLarge.override(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (driver.email.isNotEmpty)
                      Text(
                        driver.email,
                        style: theme.bodySmall.override(
                          color: theme.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            setState(() => _selectedDriverRef = value);
          },
        ),
      ),
    );
  }

  Widget _buildDateFilter(FlutterFlowTheme theme) {
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
          Text(
            _dateFilterSummary(),
            style: theme.titleSmall.override(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickFilterDate(isStart: true),
                  icon: const Icon(Icons.date_range, size: 18),
                  label: const Text('From'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickFilterDate(isStart: false),
                  icon: const Icon(Icons.event, size: 18),
                  label: const Text('To'),
                ),
              ),
              IconButton(
                tooltip: 'Clear dates',
                onPressed: _clearDateFilter,
                icon: Icon(Icons.clear, color: theme.secondaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips(FlutterFlowTheme theme) {
    return FlutterFlowChoiceChips(
      options: const [
        ChipData('All'),
        ChipData('Assigned'),
        ChipData('Out for Delivery'),
        ChipData('Completed'),
      ],
      onChanged: (val) => _onTabChipChanged(val?.firstOrNull),
      selectedChipStyle: ChipStyle(
        backgroundColor: theme.primary,
        textStyle: theme.bodyMedium.override(
          color: theme.primaryBackground,
          fontWeight: FontWeight.w600,
        ),
        iconColor: theme.primaryBackground,
        iconSize: 18,
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
      ),
      unselectedChipStyle: ChipStyle(
        backgroundColor: theme.secondaryBackground,
        textStyle: theme.bodyMedium.override(color: theme.secondaryText),
        iconColor: theme.secondaryText,
        iconSize: 18,
        elevation: 0,
        borderColor: theme.alternate,
        borderWidth: 1,
        borderRadius: BorderRadius.circular(20),
      ),
      chipSpacing: 12,
      rowSpacing: 8,
      multiselect: false,
      alignment: WrapAlignment.start,
      controller: _model.choiceChipsValueController ??=
          FormFieldController<List<String>>(['All']),
      wrapped: true,
    );
  }

  Widget _buildOrdersSection(FlutterFlowTheme theme) {
    return StreamBuilder<List<OrderItemRecord>>(
      stream: queryTenantOrderItemRecord(),
      builder: (context, itemsSnapshot) {
        if (!itemsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allItems = itemsSnapshot.data!;

        return StreamBuilder<List<OrdersRecord>>(
          key: ValueKey(
            'driver-assignments-${_selectedDriverRef?.path}-'
            '${_tabStatus?.name ?? 'all'}-'
            '${_model.filterStartDate?.millisecondsSinceEpoch}-'
            '${_model.filterEndDate?.millisecondsSinceEpoch}',
          ),
          stream: queryTenantOrdersRecord(queryBuilder: _orderQuery()),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Could not load orders: ${snapshot.error}',
                style: theme.bodyMedium.override(color: theme.error),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = filterDriverDeliveryOrders(
              snapshot.data!,
              driverRef: _selectedDriverRef,
              tabStatus: _tabStatus,
              filterStart: _model.filterStartDate,
              filterEnd: _model.filterEndDate,
            );
            final routeOrders = suggestedRouteOrders(orders);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showSuggestedRoute(routeOrders))
                  _buildRouteSection(theme, routeOrders),
                if (orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No orders assigned to this driver for the selected filters.',
                      textAlign: TextAlign.center,
                      style: theme.bodyMedium.override(
                        color: theme.secondaryText,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Assigned orders (${orders.length})',
                    style: theme.titleMedium.override(
                      font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final order in orders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DriverDeliveryOrderCard(
                        order: order,
                        items: orderListItemsForOrder(allItems, order),
                        locale: FFLocalizations.of(context).languageCode,
                        showDriverActions: false,
                      ),
                    ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRouteSection(
    FlutterFlowTheme theme,
    List<OrdersRecord> routeOrders,
  ) {
    final stops = routeOrders
        .where((order) => order.address.trim().isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: theme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Suggested route',
                  style: theme.titleMedium.override(
                    font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Text(
                '建议路线',
                style: theme.labelSmall.override(color: theme.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stops.isEmpty)
            Text(
              'Assigned orders have no delivery addresses.',
              style: theme.bodySmall.override(color: theme.secondaryText),
            )
          else
            for (var i = 0; i < stops.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.primary,
                      child: Text(
                        '${i + 1}',
                        style: theme.labelSmall.override(
                          color: theme.primaryBackground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderListOrderId(stops[i]),
                            style: theme.bodyMedium.override(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (stops[i].clientName.isNotEmpty)
                            Text(
                              stops[i].clientName,
                              style: theme.bodySmall,
                            ),
                          Text(
                            stops[i].address.trim(),
                            style: theme.bodySmall.override(
                              color: theme.secondaryText,
                            ),
                          ),
                          Text(
                            '${orderListDeliveryDateOnly(stops[i])} · '
                            '${orderListDeliveryTimeSlot(stops[i])}',
                            style: theme.bodySmall.override(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          FFButtonWidget(
            onPressed: () => _openSuggestedRoute(routeOrders),
            text: 'Open in Google Maps',
            icon: const Icon(Icons.map_outlined, size: 20),
            options: FFButtonOptions(
              width: double.infinity,
              height: 44,
              color: theme.primary,
              textStyle: theme.titleSmall.override(
                color: theme.primaryBackground,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
