import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/backend/order_navigation_helpers.dart';
import '/backend/staff_notice_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/customer_invoice_helpers.dart';
import '/backend/order_discount_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/components/credit_payment_method_button.dart';
import '/components/exact_payment_method_button.dart';
import '/components/order_discount_panel.dart';
import '/components/partial_payment_method_button.dart';
import '/components/order_product_add_panel.dart';
import '/components/order_summary_item_tile.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import '/l10n/tr.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'd_c_summary_copy_model.dart';
export 'd_c_summary_copy_model.dart';

/// Build a POS Summary Page in FlutterFlow using Firebase Firestore.
///
/// Page parameter:
/// orderRef (Document Reference to orders)
/// Collections:
/// order_items: orderRef, name, price, qty, subtotal
/// orders: total (Double), status (String), payment_method (String), paid_at
/// (DateTime)
/// UI:
/// ListView showing all order_items where orderRef matches
/// Each row shows product name, price, qty, subtotal
/// Editable qty with + / − buttons, auto update subtotal
/// Summary section:
/// Display total quantity and total amount (sum of subtotals)
/// Actions:
/// On qty change: update order_items.qty and subtotal
/// Recalculate and update orders.total in real time
/// Payment section:
/// Payment method selector: Cash / PayNow / Card
/// Button “Confirm Payment”
/// Confirm Payment action:
/// Update orders.status = "completed"
/// Save payment_method and paid_at
/// Navigate to Receipt / Print page
class DCSummaryCopyWidget extends StatefulWidget {
  const DCSummaryCopyWidget({
    super.key,
    required this.orderRef,
  });

  final DocumentReference? orderRef;

  static String routeName = 'DCSummaryCopy';
  static String routePath = '/deliverySummaryCopy';

  @override
  State<DCSummaryCopyWidget> createState() => _DCSummaryCopyWidgetState();
}

class _DCSummaryCopyWidgetState extends State<DCSummaryCopyWidget> {
  late DCSummaryCopyModel _model;
  PendingOrderPaymentSelection? _pendingPayment;
  CustomerInvoiceDiscountType _discountType =
      CustomerInvoiceDiscountType.amount;
  final _discountController = TextEditingController(text: '0');
  final _discountRemarkController = TextEditingController();
  var _discountSeeded = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _canApplyDiscount =>
      canApplyOrderDiscount(AppStateNotifier.instance.userRole);

  CustomerInvoiceDiscountInput get _discountInput {
    final parsed = double.tryParse(_discountController.text.trim()) ?? 0;
    return CustomerInvoiceDiscountInput(
      type: _discountType,
      value: parsed < 0 ? 0 : parsed,
    );
  }

  OrderPayableTotals _payableForSubtotal(double itemSubtotal) =>
      calculateOrderPayableTotals(
        itemSubtotal: itemSubtotal,
        discount: _discountInput,
      );

  void _seedDiscountFromOrder(OrdersRecord order) {
    if (_discountSeeded) {
      return;
    }
    _discountSeeded = true;
    final existing = parseOrderDiscountInput(order);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      safeSetState(() {
        _discountType = existing.type;
        _discountController.text = existing.value.toStringAsFixed(
          existing.type == CustomerInvoiceDiscountType.percent ? 0 : 2,
        );
        _discountRemarkController.text = order.discountRemark;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DCSummaryCopyModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
        AppStateNotifier.instance.syncUserRole(profile?.role);
      }
      if (mounted) safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _discountRemarkController.dispose();
    _model.dispose();

    super.dispose();
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
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: double.infinity,
                  height: 80.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            FlutterFlowIconButton(
                              borderRadius: 20.0,
                              buttonSize: 40.0,
                              fillColor: Color(0x4DFFFFFF),
                              icon: Icon(
                                Icons.arrow_back,
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                size: 20.0,
                              ),
                              onPressed: () async {
                                context.safePop();
                              },
                            ),
                            Text(
                              'Product confirmation',
                              style: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleLarge
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 12.0)),
                        ),
                        const HomeNavIconButton.onPrimary(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: widget!.orderRef == null
                          ? null
                          : () {
                              showOrderProductAddPanel(
                                context,
                                orderRef: widget!.orderRef!,
                                onItemsChanged: () async {},
                              );
                            },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text('Add Products'),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: StreamBuilder<List<OrderItemRecord>>(
                    stream: streamOrderLineItemsForOrder(widget!.orderRef!),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            '${snapshot.error}',
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).error,
                            ),
                          ),
                        );
                      }
                      // Customize what your widget looks like when it's loading.
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
                      List<OrderItemRecord> listViewOrderItemRecordList =
                          activeOrderItems(snapshot.data!);

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: listViewOrderItemRecordList.length,
                        itemBuilder: (context, listViewIndex) {
                          final listViewOrderItemRecord =
                              listViewOrderItemRecordList[listViewIndex];
                          return Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 12.0),
                            child: OrderSummaryItemTile(
                              item: listViewOrderItemRecord,
                              orderRef: widget!.orderRef!,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1.0,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(),
                    child: StreamBuilder<List<OrderItemRecord>>(
                      stream: streamOrderLineItemsForOrder(widget!.orderRef!),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).error,
                              ),
                            ),
                          );
                        }
                        // Customize what your widget looks like when it's loading.
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
                        List<OrderItemRecord> containerOrderItemRecordList =
                            activeOrderItems(snapshot.data!);

                        return Container(
                          decoration: BoxDecoration(),
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Divider(
                                  thickness: 1.0,
                                  color: FlutterFlowTheme.of(context)
                                      .alternate,
                                ),
                                StreamBuilder<List<OrderItemRecord>>(
                                      stream: streamOrderLineItemsForOrder(widget!.orderRef!),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                              '${snapshot.error}',
                                              style: TextStyle(
                                                color: FlutterFlowTheme.of(
                                                        context)
                                                    .error,
                                              ),
                                            ),
                                          );
                                        }
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        List<OrderItemRecord>
                                            containerOrderItemRecordList =
                                            activeOrderItems(snapshot.data!);

                                        return Container(
                                          width: 405.6,
                                          height: 100.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Total Qty:',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                  Text(
                                                    containerOrderItemRecordList
                                                        .length
                                                        .toString(),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Total Amount',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                  Text(
                                                    formatNumber(
                                                      functions.calculationTotal(
                                                          containerOrderItemRecordList
                                                              .map((e) =>
                                                                  e.price)
                                                              .toList(),
                                                          containerOrderItemRecordList
                                                              .map((e) => e.qty)
                                                              .toList()),
                                                      formatType:
                                                          FormatType.decimal,
                                                      decimalType:
                                                          DecimalType.automatic,
                                                      currency: '',
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                width: 274.94,
                                                height: 100.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    Divider(
                                      thickness: 1.0,
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 16.0, 0.0, 12.0),
                                      child: Text(
                                        'Payment Method',
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              font: GoogleFonts.interTight(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: StreamBuilder<OrdersRecord>(
                                        stream: OrdersRecord.getDocument(
                                            widget.orderRef!),
                                        builder: (context, orderSnapshot) {
                                          if (orderSnapshot.hasData) {
                                            _seedDiscountFromOrder(
                                              orderSnapshot.data!,
                                            );
                                          }
                                          final itemSubtotal =
                                              functions.calculationTotal(
                                            containerOrderItemRecordList
                                                .map((e) => e.price)
                                                .toList(),
                                            containerOrderItemRecordList
                                                .map((e) => e.qty)
                                                .toList(),
                                          );
                                          return OrderDiscountPanel(
                                            discountType: _discountType,
                                            discountController:
                                                _discountController,
                                            remarkController:
                                                _discountRemarkController,
                                            totals: _payableForSubtotal(
                                              itemSubtotal,
                                            ),
                                            canEdit: _canApplyDiscount,
                                            existingRemark:
                                                orderSnapshot.hasData
                                                    ? orderSnapshot
                                                        .data!.discountRemark
                                                    : '',
                                            onTypeChanged: (type) =>
                                                safeSetState(
                                              () => _discountType = type,
                                            ),
                                            onValueChanged: () =>
                                                safeSetState(() {}),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 16.0),
                                      child: StreamBuilder<OrdersRecord>(
                                        stream: OrdersRecord.getDocument(widget.orderRef!),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Text(
                                                '${snapshot.error}',
                                                style: TextStyle(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                ),
                                              ),
                                            );
                                          }
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return Center(
                                              child: SizedBox(
                                                width: 50.0,
                                                height: 50.0,
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          final rowOrdersRecord = snapshot.data!;
                                          final itemSubtotal =
                                              functions.calculationTotal(
                                            containerOrderItemRecordList
                                                .map((e) => e.price)
                                                .toList(),
                                            containerOrderItemRecordList
                                                .map((e) => e.qty)
                                                .toList(),
                                          );
                                          final saleTotal =
                                              _payableForSubtotal(itemSubtotal)
                                                  .total;

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              if (_pendingPayment != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 12.0),
                                                  child: Text(
                                                    describePendingOrderPayment(
                                                      _pendingPayment!,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          color:
                                                              FlutterFlowTheme
                                                                      .of(context)
                                                                  .primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                              SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              PartialPaymentMethodButton(
                                                orderRef:
                                                    rowOrdersRecord.reference,
                                                paymentType: 'Cash',
                                                label: 'Cash',
                                                icon: FaIcon(
                                                  FontAwesomeIcons
                                                      .moneyBillWaveAlt,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .info,
                                                  size: 22.0,
                                                ),
                                                currentPaymentType:
                                                    rowOrdersRecord
                                                        .paymentType,
                                                saleTotal: saleTotal,
                                                pendingSelection:
                                                    _pendingPayment,
                                                onSelectionChanged:
                                                    (selection) => safeSetState(
                                                  () => _pendingPayment =
                                                      selection,
                                                ),
                                              ),
                                              PartialPaymentMethodButton(
                                                orderRef:
                                                    rowOrdersRecord.reference,
                                                paymentType: 'Paynow',
                                                label: 'PayNow',
                                                icon: Icon(
                                                  Icons.qr_code_2,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .info,
                                                  size: 24.0,
                                                ),
                                                currentPaymentType:
                                                    rowOrdersRecord
                                                        .paymentType,
                                                saleTotal: saleTotal,
                                                pendingSelection:
                                                    _pendingPayment,
                                                onSelectionChanged:
                                                    (selection) => safeSetState(
                                                  () => _pendingPayment =
                                                      selection,
                                                ),
                                              ),
                                              PartialPaymentMethodButton(
                                                orderRef:
                                                    rowOrdersRecord.reference,
                                                paymentType: 'Card',
                                                label: 'Card',
                                                icon: Icon(
                                                  Icons.credit_card,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .info,
                                                  size: 24.0,
                                                ),
                                                currentPaymentType:
                                                    rowOrdersRecord
                                                        .paymentType,
                                                saleTotal: saleTotal,
                                                pendingSelection:
                                                    _pendingPayment,
                                                onSelectionChanged:
                                                    (selection) => safeSetState(
                                                  () => _pendingPayment =
                                                      selection,
                                                ),
                                              ),
                                              ExactPaymentMethodButton(
                                                orderRef:
                                                    rowOrdersRecord.reference,
                                                paymentType: 'Shopify',
                                                label: 'Shopify',
                                                icon: FaIcon(
                                                  FontAwesomeIcons.shopify,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .info,
                                                  size: 22.0,
                                                ),
                                                currentPaymentType:
                                                    rowOrdersRecord
                                                        .paymentType,
                                                saleTotal: saleTotal,
                                                pendingSelection:
                                                    _pendingPayment,
                                                onSelectionChanged:
                                                    (selection) => safeSetState(
                                                  () => _pendingPayment =
                                                      selection,
                                                ),
                                              ),
                                              ExactPaymentMethodButton(
                                                orderRef:
                                                    rowOrdersRecord.reference,
                                                paymentType: 'Shopee',
                                                label: 'Shopee',
                                                icon: Icon(
                                                  Icons.shopping_bag_outlined,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .info,
                                                  size: 24.0,
                                                ),
                                                currentPaymentType:
                                                    rowOrdersRecord
                                                        .paymentType,
                                                saleTotal: saleTotal,
                                                pendingSelection:
                                                    _pendingPayment,
                                                onSelectionChanged:
                                                    (selection) => safeSetState(
                                                  () => _pendingPayment =
                                                      selection,
                                                ),
                                              ),
                                              CreditPaymentMethodButton(
                                                orderRef: rowOrdersRecord.reference,
                                                currentPaymentType:
                                                    rowOrdersRecord.paymentType,
                                                pendingSelection:
                                                    _pendingPayment,
                                                onSelectionChanged:
                                                    (selection) => safeSetState(
                                                  () => _pendingPayment =
                                                      selection,
                                                ),
                                              ),
                                            ],
                                          ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 16.0, 0.0, 0.0),
                                      child: StreamBuilder<OrdersRecord>(
                                        stream: OrdersRecord.getDocument(
                                            widget!.orderRef!),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Text(
                                                '${snapshot.error}',
                                                style: TextStyle(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                ),
                                              ),
                                            );
                                          }
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return Center(
                                              child: SizedBox(
                                                width: 50.0,
                                                height: 50.0,
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          final buttonOrdersRecord =
                                              snapshot.data!;

                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FFButtonWidget(
                                                onPressed: () async {
                                                  final itemSubtotal =
                                                      functions.calculationTotal(
                                                    containerOrderItemRecordList
                                                        .map((e) => e.price)
                                                        .toList(),
                                                    containerOrderItemRecordList
                                                        .map((e) => e.qty)
                                                        .toList(),
                                                  );
                                                  final payable =
                                                      _payableForSubtotal(
                                                    itemSubtotal,
                                                  );
                                                  if (_canApplyDiscount) {
                                                    if (payable.discount >
                                                            0.005 &&
                                                        _discountRemarkController
                                                            .text
                                                            .trim()
                                                            .isEmpty) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              tr(
                                                                context,
                                                                'pos.discount.remarkRequired',
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      return;
                                                    }
                                                    await persistOrderDiscountFields(
                                                      widget!.orderRef!,
                                                      payable,
                                                      remark:
                                                          _discountRemarkController
                                                              .text,
                                                    );
                                                  }
                                                  if (!context.mounted) {
                                                    return;
                                                  }
                                                  final paid =
                                                      await completeOrderSummaryPayment(
                                                    context,
                                                    orderRef:
                                                        widget!.orderRef!,
                                                    saleTotal: payable.total,
                                                    pendingSelection:
                                                        _pendingPayment,
                                                  );
                                                  if (!paid || !context.mounted) {
                                                    return;
                                                  }
                                                  safeSetState(
                                                    () => _pendingPayment = null,
                                                  );
                                                  final paidOrder =
                                                      await OrdersRecord
                                                          .getDocumentOnce(
                                                    widget!.orderRef!,
                                                  );
                                                  try {
                                                    await ensureStaffOrderCreatedNotice(
                                                      paidOrder,
                                                    );
                                                  } catch (_) {}
                                                  if (!context.mounted) {
                                                    return;
                                                  }
                                                  finishDeliveryPaymentAndShowOrderDetail(
                                                    context,
                                                    widget!.orderRef!,
                                                  );
                                                },
                                                text: 'Payment Done',
                                                options: FFButtonOptions(
                                                  width: double.infinity,
                                                  height: 48.0,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  textStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleMedium
                                                          .override(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
