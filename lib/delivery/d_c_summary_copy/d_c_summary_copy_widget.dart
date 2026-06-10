import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/backend/order_navigation_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/components/home_nav_button.dart';
import '/components/credit_payment_method_button.dart';
import '/components/exact_payment_method_button.dart';
import '/components/partial_payment_method_button.dart';
import '/components/order_summary_item_tile.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
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

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DCSummaryCopyModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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
                              'Order Summary',
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
                  child: StreamBuilder<List<OrderItemRecord>>(
                    stream: queryOrderItemRecord(
                      queryBuilder: (orderItemRecord) => orderItemRecord.where(
                        'orderRef',
                        isEqualTo: widget!.orderRef,
                      ),
                    ),
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
                    child: StreamBuilder<List<OrderItemRecord>>(
                      stream: queryOrderItemRecord(
                        queryBuilder: (orderItemRecord) =>
                            orderItemRecord.where(
                          'orderRef',
                          isEqualTo: widget!.orderRef,
                        ),
                      ),
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
                                      stream: queryOrderItemRecord(
                                        queryBuilder: (orderItemRecord) =>
                                            orderItemRecord.where(
                                          'orderRef',
                                          isEqualTo: widget!.orderRef,
                                        ),
                                      ),
                                      builder: (context, snapshot) {
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
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 16.0),
                                      child: StreamBuilder<OrdersRecord>(
                                        stream: OrdersRecord.getDocument(widget.orderRef!),
                                        builder: (context, snapshot) {
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

                                          return SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
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
                                              ),
                                              CreditPaymentMethodButton(
                                                orderRef: rowOrdersRecord.reference,
                                                currentPaymentType:
                                                    rowOrdersRecord.paymentType,
                                              ),
                                            ],
                                          ),
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
                                                  await buttonOrdersRecord
                                                      .reference
                                                      .update(
                                                    createOrdersRecordData(
                                                      totalAmount: functions
                                                          .calculationTotal(
                                                        containerOrderItemRecordList
                                                            .map((e) => e.price)
                                                            .toList(),
                                                        containerOrderItemRecordList
                                                            .map((e) => e.qty)
                                                            .toList(),
                                                      ),
                                                    ),
                                                  );
                                                  if (!context.mounted) {
                                                    return;
                                                  }
                                                  context.pushNamed(
                                                    CreateOrderFormWidget
                                                        .routeName,
                                                    queryParameters:
                                                        orderRefQueryParams(
                                                      widget!.orderRef!,
                                                    ),
                                                    extra: orderRefExtra(
                                                      widget!.orderRef!,
                                                    ),
                                                  );
                                                },
                                                text: 'Payment Done - Delivery detail',
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
