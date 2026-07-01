import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/backend/order_id_service.dart';
import '/backend/order_item_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/order_balance_helpers.dart';
import '/backend/order_production_menu_helpers.dart';
import '/backend/retail_payment_helpers.dart';
import '/components/credit_payment_method_button.dart';
import '/components/exact_payment_method_button.dart';
import '/components/order_balance_summary_panel.dart';
import '/components/partial_payment_method_button.dart';
import '/components/order_summary_item_tile.dart';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'retail_summary_model.dart';
export 'retail_summary_model.dart';

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
class RetailSummaryWidget extends StatefulWidget {
  const RetailSummaryWidget({
    super.key,
    required this.orderRef,
  });

  final DocumentReference? orderRef;

  static String routeName = 'RetailSummary';
  static String routePath = '/retailSummary';

  @override
  State<RetailSummaryWidget> createState() => _RetailSummaryWidgetState();
}

class _RetailSummaryWidgetState extends State<RetailSummaryWidget> {
  late RetailSummaryModel _model;
  PendingOrderPaymentSelection? _pendingPayment;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RetailSummaryModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      if (mounted) safeSetState(() {});
    });
  }

  @override
  void dispose() {
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
                              tr(context, 'pos.summary.title'),
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
                        const AppBarLanguageHomeActions(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                  child: StreamBuilder<List<OrderItemRecord>>(
                    stream: streamOrderLineItemsForOrder(widget!.orderRef!),
                    builder: (context, snapshot) {
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
                    child: Container(
                      decoration: BoxDecoration(),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Divider(
                              thickness: 1.0,
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                            StreamBuilder<List<OrderItemRecord>>(
                              stream: streamOrderLineItemsForOrder(widget!.orderRef!),
                              builder: (context, snapshot) {
                                // Customize what your widget looks like when it's loading.
                                if (!snapshot.hasData) {
                                  return Center(
                                    child: SizedBox(
                                      width: 50.0,
                                      height: 50.0,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          FlutterFlowTheme.of(context).primary,
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
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            tr(context, 'pos.summary.totalQty'),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
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
                                            containerOrderItemRecordList.length
                                                .toString(),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
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
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            tr(context, 'pos.summary.totalAmount'),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
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
                                                      .map((e) => e.price)
                                                      .toList(),
                                                  containerOrderItemRecordList
                                                      .map((e) => e.qty)
                                                      .toList()),
                                              formatType: FormatType.decimal,
                                              decimalType:
                                                  DecimalType.automatic,
                                              currency: '',
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
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
                                        width: 100.0,
                                        height: 100.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
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
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                            StreamBuilder<List<OrderItemRecord>>(
                              stream: streamOrderLineItemsForOrder(widget!.orderRef!),
                              builder: (context, itemSnapshot) {
                                if (!itemSnapshot.hasData) {
                                  return const SizedBox.shrink();
                                }
                                final summaryItems =
                                    activeOrderItems(itemSnapshot.data!);
                                final saleTotal = functions.calculationTotal(
                                  summaryItems.map((e) => e.price).toList(),
                                  summaryItems.map((e) => e.qty).toList(),
                                );
                                return StreamBuilder<OrdersRecord>(
                                  stream: OrdersRecord.getDocument(
                                      widget!.orderRef!),
                                  builder: (context, orderSnapshot) {
                                    if (!orderSnapshot.hasData) {
                                      return const SizedBox.shrink();
                                    }
                                    return OrderBalanceSummaryPanel(
                                      order: orderSnapshot.data!,
                                      saleTotal: saleTotal,
                                    );
                                  },
                                );
                              },
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 16.0, 0.0, 12.0),
                              child: Text(
                                tr(context, 'pos.payment.method'),
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.interTight(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 16.0),
                              child: StreamBuilder<List<OrderItemRecord>>(
                                stream:
                                    streamOrderLineItemsForOrder(widget!.orderRef!),
                                builder: (context, itemSnapshot) {
                                  if (!itemSnapshot.hasData) {
                                    return Center(
                                      child: SizedBox(
                                        width: 50.0,
                                        height: 50.0,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  final summaryItems =
                                      activeOrderItems(itemSnapshot.data!);
                                  final saleTotal = functions.calculationTotal(
                                    summaryItems.map((e) => e.price).toList(),
                                    summaryItems.map((e) => e.qty).toList(),
                                  );

                                  return StreamBuilder<OrdersRecord>(
                                stream: OrdersRecord.getDocument(widget.orderRef!),
                                builder: (context, snapshot) {
                                  // Customize what your widget looks like when it's loading.
                                  if (!snapshot.hasData) {
                                    return Center(
                                      child: SizedBox(
                                        width: 50.0,
                                        height: 50.0,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  final rowOrdersRecord = snapshot.data!;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (_pendingPayment != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 12.0),
                                          child: Text(
                                            describePendingOrderPayment(
                                              _pendingPayment!,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      PartialPaymentMethodButton(
                                        orderRef: rowOrdersRecord.reference,
                                        paymentType: 'Cash',
                                        label: tr(context, 'pos.payment.cash'),
                                        icon: FaIcon(
                                          FontAwesomeIcons.moneyBillWaveAlt,
                                          color: FlutterFlowTheme.of(context)
                                              .info,
                                          size: 22.0,
                                        ),
                                        currentPaymentType:
                                            rowOrdersRecord.paymentType,
                                        saleTotal: saleTotal,
                                        pendingSelection: _pendingPayment,
                                        onSelectionChanged: (selection) =>
                                            safeSetState(
                                          () => _pendingPayment = selection,
                                        ),
                                        useBodySmall: true,
                                      ),
                                      PartialPaymentMethodButton(
                                        orderRef: rowOrdersRecord.reference,
                                        paymentType: 'Paynow',
                                        label: tr(context, 'pos.payment.paynow'),
                                        icon: Icon(
                                          Icons.qr_code_2,
                                          color: FlutterFlowTheme.of(context)
                                              .info,
                                          size: 24.0,
                                        ),
                                        currentPaymentType:
                                            rowOrdersRecord.paymentType,
                                        saleTotal: saleTotal,
                                        pendingSelection: _pendingPayment,
                                        onSelectionChanged: (selection) =>
                                            safeSetState(
                                          () => _pendingPayment = selection,
                                        ),
                                        useBodySmall: true,
                                      ),
                                      PartialPaymentMethodButton(
                                        orderRef: rowOrdersRecord.reference,
                                        paymentType: 'Card',
                                        label: tr(context, 'pos.payment.card'),
                                        icon: Icon(
                                          Icons.credit_card,
                                          color: FlutterFlowTheme.of(context)
                                              .info,
                                          size: 24.0,
                                        ),
                                        currentPaymentType:
                                            rowOrdersRecord.paymentType,
                                        saleTotal: saleTotal,
                                        pendingSelection: _pendingPayment,
                                        onSelectionChanged: (selection) =>
                                            safeSetState(
                                          () => _pendingPayment = selection,
                                        ),
                                        useBodySmall: true,
                                      ),
                                      ExactPaymentMethodButton(
                                        orderRef: rowOrdersRecord.reference,
                                        paymentType: 'Shopify',
                                        label: tr(context, 'pos.payment.shopify'),
                                        icon: FaIcon(
                                          FontAwesomeIcons.shopify,
                                          color: FlutterFlowTheme.of(context)
                                              .info,
                                          size: 22.0,
                                        ),
                                        currentPaymentType:
                                            rowOrdersRecord.paymentType,
                                        saleTotal: saleTotal,
                                        pendingSelection: _pendingPayment,
                                        onSelectionChanged: (selection) =>
                                            safeSetState(
                                          () => _pendingPayment = selection,
                                        ),
                                        useBodySmall: true,
                                      ),
                                      ExactPaymentMethodButton(
                                        orderRef: rowOrdersRecord.reference,
                                        paymentType: 'Shopee',
                                        label: tr(context, 'pos.payment.shopee'),
                                        icon: Icon(
                                          Icons.shopping_bag_outlined,
                                          color: FlutterFlowTheme.of(context)
                                              .info,
                                          size: 24.0,
                                        ),
                                        currentPaymentType:
                                            rowOrdersRecord.paymentType,
                                        saleTotal: saleTotal,
                                        pendingSelection: _pendingPayment,
                                        onSelectionChanged: (selection) =>
                                            safeSetState(
                                          () => _pendingPayment = selection,
                                        ),
                                        useBodySmall: true,
                                      ),
                                      CreditPaymentMethodButton(
                                        orderRef: rowOrdersRecord.reference,
                                        currentPaymentType:
                                            rowOrdersRecord.paymentType,
                                        pendingSelection: _pendingPayment,
                                        onSelectionChanged: (selection) =>
                                            safeSetState(
                                          () => _pendingPayment = selection,
                                        ),
                                        useBodySmall: true,
                                      ),
                                    ],
                                  ),
                                      ),
                                    ],
                                  );
                                },
                              );
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 8.0, 0.0, 0.0),
                              child: StreamBuilder<List<OrderItemRecord>>(
                                stream: streamOrderLineItemsForOrder(widget!.orderRef!),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }
                                  final buttonOrderItemRecordList =
                                      activeOrderItems(snapshot.data!);
                                  final saleTotal = functions.calculationTotal(
                                    buttonOrderItemRecordList
                                        .map((e) => e.price)
                                        .toList(),
                                    buttonOrderItemRecordList
                                        .map((e) => e.qty)
                                        .toList(),
                                  );

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      FFButtonWidget(
                                        onPressed: () async {
                                          final paid =
                                              await completeOrderSummaryPayment(
                                            context,
                                            orderRef: widget!.orderRef!,
                                            saleTotal: saleTotal,
                                            pendingSelection: _pendingPayment,
                                          );
                                          if (!paid || !context.mounted) {
                                            return;
                                          }
                                          safeSetState(
                                            () => _pendingPayment = null,
                                          );
                                          final order =
                                              await OrdersRecord.getDocumentOnce(
                                            widget!.orderRef!,
                                          );
                                          final balanceDue = calculateBalanceDue(
                                            saleTotal: saleTotal,
                                            amountPaid:
                                                readOrderAmountPaid(order),
                                          );
                                          if (balanceDue <= 0.005) {
                                            await completeRetailPaymentAndOpenReceipt(
                                              context,
                                              orderRef: widget!.orderRef!,
                                            );
                                          }
                                        },
                                        text: tr(context, 'pos.payment.done'),
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.white,
                                        ),
                                        options: FFButtonOptions(
                                          width: double.infinity,
                                          height: 44.0,
                                          color: FlutterFlowTheme.of(context)
                                              .secondary,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          final orderSnap =
                                              await widget!.orderRef!.get();
                                          final order = OrdersRecord
                                              .fromSnapshot(orderSnap);
                                          final orderId =
                                              OrderIdService.isRetailOrderId(
                                                    order.orderId,
                                                  )
                                                  ? order.orderId
                                                  : await OrderIdService
                                                      .nextRetailOrderId();
                                          final amountPaid =
                                              readOrderAmountPaid(order);
                                          final balanceDue =
                                              calculateBalanceDue(
                                            saleTotal: saleTotal,
                                            amountPaid: amountPaid,
                                          );
                                          await widget!.orderRef!.update(
                                            createOrdersRecordData(
                                              totalAmount: saleTotal,
                                              total: saleTotal,
                                              orderId: orderId,
                                              amountPaid: amountPaid > 0.005
                                                  ? amountPaid
                                                  : null,
                                              balanceDue: balanceDue > 0.005
                                                  ? balanceDue
                                                  : 0,
                                              deliveryDate:
                                                  order.createdTime ??
                                                      order.deliveryDate ??
                                                      getCurrentTimestamp,
                                              pickupDelivery: order
                                                      .pickupDelivery
                                                      .isNotEmpty
                                                  ? order.pickupDelivery
                                                  : 'Retail',
                                            ),
                                          );

                                          context.pushNamed(
                                            ReceiptPreviewpage2Widget
                                                .routeName,
                                            queryParameters: {
                                              'orderRef': serializeParam(
                                                widget!.orderRef,
                                                ParamType.DocumentReference,
                                              ),
                                            }.withoutNulls,
                                          );
                                        },
                                        text: tr(context, 'pos.payment.confirm'),
                                        options: FFButtonOptions(
                                          width: double.infinity,
                                          height: 50.0,
                                          padding: EdgeInsets.all(8.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: FlutterFlowTheme.of(context)
                                              .success,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleMedium
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryBackground,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderSide: BorderSide(
                                            color: Colors.transparent,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FFButtonWidget(
                                        onPressed: () {
                                          if (widget.orderRef == null) {
                                            return;
                                          }
                                          openProductionMenuPreview(
                                            context,
                                            widget.orderRef!,
                                          );
                                        },
                                        text: tr(context, 'pos.action.productionMenu'),
                                        icon: Icon(
                                          Icons.restaurant_menu,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                        ),
                                        options: FFButtonOptions(
                                          width: double.infinity,
                                          height: 50.0,
                                          padding: const EdgeInsets.all(8.0),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleMedium
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                              ),
                                          elevation: 0.0,
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
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
