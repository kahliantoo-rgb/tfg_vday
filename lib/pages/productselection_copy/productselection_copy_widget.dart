import '/auth/firebase_auth/auth_util.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/backend.dart';
import '/backend/create_order_service.dart';
import '/backend/custom_product_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/backend/product_category_helpers.dart';
import '/backend/product_selection_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/create_order_form_items_panel.dart';
import '/components/home_nav_button.dart';
import '/backend/order_checkout_helpers.dart';
import '/backend/order_id_service.dart';
import '/backend/order_status_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/components/remark_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'productselection_copy_model.dart';
export 'productselection_copy_model.dart';

/// Build a Product Selection Page in FlutterFlow using Firebase Firestore.
///
/// Collections:
/// product: name (String), price (Double), image (Image), sku (String),
/// isActive (Boolean)
/// order_items: orderRef (Ref orders), productRef (Ref product), name
/// (String), price (Double), qty (Int), subtotal (Double)
/// Page parameter:
/// orderRef (Document Reference to orders)
/// UI:
/// Display products using GridView or ListView
/// Query only products where isActive == true
/// Each product card shows image, name, price, and “Add” button
/// Add button action:
/// If order_items exists for same orderRef + productRef, increase qty and
/// update subtotal
/// Else create new order_items with qty = 1 and subtotal = price
/// Show Snackbar confirmation
/// Bottom section:
/// Show total qty and total amount
/// Button “Cashier”: update orders.order_type = "cashier", go to POS page
/// Button “Delivery”: update orders.order_type = "delivery", go to delivery
/// form
class ProductselectionCopyWidget extends StatefulWidget {
  const ProductselectionCopyWidget({
    super.key,
    required this.orderRef,
  });

  final DocumentReference? orderRef;

  static String routeName = 'ProductselectionCopy';
  static String routePath = '/productselectionCopy';

  @override
  State<ProductselectionCopyWidget> createState() =>
      _ProductselectionCopyWidgetState();
}

class _ProductselectionCopyWidgetState
    extends State<ProductselectionCopyWidget> {
  late ProductselectionCopyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _tenantReady = false;

  /// Cached once per page visit — avoids re-subscribing Firestore listeners on
  /// every rebuild (search/filter), which can trigger web SDK ca9/b815 asserts.
  Stream<List<ProductRecord>>? _activeProductsStream;
  Stream<List<String>>? _tenantCategoriesStream;
  Stream<OrdersRecord>? _orderStream;
  Stream<List<OrderItemRecord>>? _orderItemsStream;

  void _ensureTenantStreams() {
    _activeProductsStream ??= queryActiveProductsForTenant();
    _tenantCategoriesStream ??= streamTenantProductCategories();
    final orderRef = widget.orderRef;
    if (orderRef != null) {
      _orderStream ??= OrdersRecord.getDocument(orderRef);
      _orderItemsStream ??= streamOrderLineItemsForOrder(orderRef);
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductselectionCopyModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      if (mounted) {
        _ensureTenantStreams();
        safeSetState(() => _tenantReady = true);
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderRef == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'product.select.title')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              tr(context, 'product.select.missingOrderRef'),
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
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
                onPressed: () {
                  context.safePop();
                },
              ),
              title: Text(
                tr(context, 'product.select.title'),
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      font: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleLarge.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleLarge.fontStyle,
                    ),
              ),
              actions: const [
                AppBarLanguageHomeActions(),
              ],
              centerTitle: true,
              elevation: 2.0,
            ),
            body: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: SafeArea(
              top: true,
              child: !_tenantReady
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<ProductRecord>>(
                        stream: _activeProductsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  tr(context, 'product.select.loadError',
                                      params: {'error': '${snapshot.error}'}),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
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
                          List<ProductRecord> listViewProductRecordList =
                              snapshot.data!;
                          if (listViewProductRecordList.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  tr(context, 'product.select.noActive'),
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium,
                                ),
                              ),
                            );
                          }

                          final filteredProducts = applyProductSelectionFilters(
                            products: listViewProductRecordList,
                            searchQuery: _model.searchController?.text ?? '',
                            category: _model.selectedCategory,
                          );

                          return StreamBuilder<List<String>>(
                            stream: _tenantCategoriesStream,
                            builder: (context, categorySnapshot) {
                              final categories = mergeProductCategoryOptions(
                                managedCategories: categorySnapshot.data ??
                                    defaultProductCategories,
                                productCategories: extractProductCategories(
                                  listViewProductRecordList,
                                ),
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildProductSearchAndFilter(
                                    context,
                                    categories: categories,
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (filteredProducts.isEmpty)
                                            Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Text(
                                                tr(context,
                                                    'product.select.noMatch'),
                                                textAlign: TextAlign.center,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium,
                                              ),
                                            )
                                          else
                                            _buildProductSelectionGrid(
                                              context,
                                              filteredProducts,
                                            ),
                                          if (widget.orderRef != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                12,
                                                8,
                                                12,
                                                0,
                                              ),
                                              child: CreateOrderFormItemsPanel(
                                                orderRef: widget.orderRef!,
                                              ),
                                            ),
                                          _buildProductSelectionFooter(context),
                                        ],
                                      ),
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
        );
  }

  Widget _buildProductSelectionFooter(BuildContext context) {
    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  tr(context, 'product.select.customPrompt'),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Container(
                                  width: double.infinity,
                                  child: TextFormField(
                                    controller: _model.textController1,
                                    focusNode: _model.textFieldFocusNode1,
                                    autofocus: false,
                                    enabled: true,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                      hintText: tr(context, 'product.select.customName'),
                                      hintStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    cursorColor: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    enableInteractiveSelection: true,
                                    validator: _model.textController1Validator
                                        .asValidator(context),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  child: TextFormField(
                                    controller: _model.textController2,
                                    focusNode: _model.textFieldFocusNode2,
                                    autofocus: false,
                                    enabled: true,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                      hintText: tr(context, 'product.select.remark'),
                                      hintStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    cursorColor: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    enableInteractiveSelection: true,
                                    validator: _model.textController2Validator
                                        .asValidator(context),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: 20.0,
                                        child: TextFormField(
                                          controller: _model.textController3,
                                          focusNode: _model.textFieldFocusNode3,
                                          autofocus: false,
                                          enabled: true,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontStyle,
                                                    ),
                                            hintText: tr(context, 'product.form.price'),
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontStyle,
                                                    ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
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
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                          enableInteractiveSelection: true,
                                          validator: _model
                                              .textController3Validator
                                              .asValidator(context),
                                        ),
                                      ),
                                    ),
                                    FFButtonWidget(
                                      onPressed: () => runProductSelectionAction(
                                        context,
                                        () async {
                                          final added =
                                              await submitCustomProductWithPhotoChoice(
                                            context: context,
                                            orderRef: widget!.orderRef,
                                            name: _model.textController1.text,
                                            qty: 1,
                                            price: double.tryParse(
                                              _model.textController3.text,
                                            ),
                                            remark: _model.textController2.text,
                                          );
                                          if (!added || !context.mounted) {
                                            return;
                                          }
                                          await recalculateOrderTotals(
                                            widget!.orderRef!,
                                          );
                                          _model.textController1?.clear();
                                          _model.textController2?.clear();
                                          _model.textController3?.clear();
                                          if (!context.mounted) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                tr(context,
                                                    'product.select.addedToCart'),
                                                style: TextStyle(
                                                  color:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primaryText,
                                                ),
                                              ),
                                              duration: const Duration(
                                                milliseconds: 4000,
                                              ),
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondary,
                                            ),
                                          );
                                        },
                                      ),
                                      text: tr(context, 'product.select.createCustom'),
                                      options: FFButtonOptions(
                                        width: 100.0,
                                        height: 40.0,
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 0.0, 16.0, 0.0),
                                        iconPadding:
                                            EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                        color: FlutterFlowTheme.of(context)
                                            .secondary,
                                        textStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              font: GoogleFonts.interTight(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                              color: FlutterFlowTheme.of(
                                                      context)
                                                  .primaryText,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                        elevation: 0.0,
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 8),
                          Text(
                            tr(context, 'product.select.chooseMethod'),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
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
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                          _buildOrderMethodSelector(context),
                            ],
                          ),
                        );
  }

  Widget _buildOrderMethodSelector(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final orderRef = widget.orderRef!;

    return StreamBuilder<OrdersRecord>(
      stream: _orderStream,
      builder: (context, orderSnapshot) {
        if (orderSnapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              tr(context, 'product.select.orderLoadError',
                  params: {'error': '${orderSnapshot.error}'}),
              style: theme.bodySmall.override(color: theme.error),
            ),
          );
        }

        return StreamBuilder<List<OrderItemRecord>>(
          stream: _orderItemsStream,
          builder: (context, itemsSnapshot) {
            if (itemsSnapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  tr(context, 'product.select.cartLoadError',
                      params: {
                        'error': describeFirestoreError(itemsSnapshot.error!),
                      }),
                  style: theme.bodySmall.override(color: theme.error),
                ),
              );
            }

            final waitingForOrder = orderSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !orderSnapshot.hasData;
            final waitingForItems = itemsSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !itemsSnapshot.hasData;

            if (waitingForOrder || waitingForItems) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final order = orderSnapshot.data;
            if (order == null) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  tr(context, 'product.select.orderNotFound'),
                  style: theme.bodySmall.override(color: theme.error),
                ),
              );
            }

            final orderItems = itemsSnapshot.data ?? const [];
            final hasOrderItems = orderItems.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: hasOrderItems
                          ? () => runProductSelectionAction(
                                context,
                                () async {
                                  final retailOrderId =
                                      OrderIdService.isRetailOrderId(
                                            order.orderId,
                                          )
                                          ? order.orderId
                                          : await OrderIdService
                                              .nextRetailOrderId();
                                  await stampOrderCompanyRefBeforeCheckout(
                                    orderRef,
                                  );
                                  final freshOrder =
                                      await OrdersRecord.getDocumentOnce(
                                    orderRef,
                                  );
                                  await orderRef.update(
                                    buildOrderCheckoutPatch(
                                      freshOrder,
                                      {
                                        ...createTenantOrdersRecordData(
                                          orderType: 'Retail',
                                          orderId: retailOrderId,
                                          pickupDelivery: 'Retail',
                                          deliveryDate:
                                              freshOrder.createdTime ??
                                                  getCurrentTimestamp,
                                        ),
                                        ...createOrderStatusUpdateData(
                                          OrderStatus.pending,
                                        ),
                                      },
                                    ),
                                  );
                                  final createdOrder =
                                      await OrdersRecord.getDocumentOnce(
                                    orderRef,
                                  );
                                  await auditLogCreateOrder(createdOrder);

                                  context.pushNamed(
                                    RetailSummaryWidget.routeName,
                                    queryParameters: {
                                      'orderRef': serializeParam(
                                        orderRef,
                                        ParamType.DocumentReference,
                                      ),
                                    }.withoutNulls,
                                  );
                                },
                              )
                          : null,
                      text: tr(context, 'product.select.retail'),
                      options: FFButtonOptions(
                        height: 40.0,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16.0,
                          0.0,
                          16.0,
                          0.0,
                        ),
                        color: theme.primary,
                        textStyle: theme.titleSmall.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                          ),
                          color: Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: hasOrderItems
                          ? () => runProductSelectionAction(
                                context,
                                () async {
                                  final deliveryOrderId =
                                      OrderIdService.isDeliveryOrderId(
                                            order.orderId,
                                          )
                                          ? order.orderId
                                          : await OrderIdService
                                              .nextDeliveryOrderId();
                                  final deliverySaleTotal =
                                      functions.calculationTotal(
                                    orderItems.map((e) => e.price).toList(),
                                    orderItems.map((e) => e.qty).toList(),
                                  );
                                  await stampOrderCompanyRefBeforeCheckout(
                                    orderRef,
                                  );
                                  final freshOrder =
                                      await OrdersRecord.getDocumentOnce(
                                    orderRef,
                                  );
                                  await orderRef.update(
                                    buildOrderCheckoutPatch(
                                      freshOrder,
                                      {
                                        ...createTenantOrdersRecordData(
                                          clientName: freshOrder.clientName,
                                          orderId: deliveryOrderId,
                                          pickupDelivery: 'Delivery',
                                          totalAmount: deliverySaleTotal,
                                          total: deliverySaleTotal,
                                          productSelection:
                                              orderItems.isNotEmpty
                                                  ? orderItems.first.reference
                                                  : null,
                                          totalQty:
                                              functions.calculateTotalItem(
                                            orderItems.length,
                                          ),
                                          orderType: 'Delivery',
                                        ),
                                        ...createOrderStatusUpdateData(
                                          OrderStatus.pending,
                                        ),
                                      },
                                    ),
                                  );
                                  final createdOrder =
                                      await OrdersRecord.getDocumentOnce(
                                    orderRef,
                                  );
                                  await auditLogCreateOrder(createdOrder);

                                  context.pushNamed(
                                    CreateOrderFormWidget.routeName,
                                    queryParameters: {
                                      'orderRef': serializeParam(
                                        orderRef,
                                        ParamType.DocumentReference,
                                      ),
                                    }.withoutNulls,
                                    extra: <String, dynamic>{
                                      'orderRef': orderRef,
                                    },
                                  );
                                },
                              )
                          : null,
                      text: tr(context, 'product.select.deliveryPickUp'),
                      options: FFButtonOptions(
                        height: 40.0,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16.0,
                          0.0,
                          16.0,
                          0.0,
                        ),
                        color: theme.primary,
                        textStyle: theme.titleSmall.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                          ),
                          color: Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductSearchAndFilter(
    BuildContext context, {
    required List<String> categories,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final hasSearchText = _model.searchController!.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _model.searchController,
            focusNode: _model.searchFocusNode,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: tr(context, 'product.select.searchHint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasSearchText
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _model.searchController!.clear();
                        setState(() {});
                      },
                    )
                  : null,
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
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr(context, 'product.select.category'),
                style: theme.labelMedium.override(
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(tr(context, 'common.all')),
                    selected: _model.selectedCategory == null,
                    onSelected: (_) {
                      setState(() => _model.selectedCategory = null);
                    },
                  ),
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: _model.selectedCategory == category,
                        onSelected: (_) {
                          setState(() => _model.selectedCategory = category);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addCatalogProductToOrder(
    BuildContext context,
    ProductRecord product,
  ) async {
    if (widget.orderRef == null) {
      return;
    }
    final blocked = await TenantContext.instance.ensureReadyForTenantWrite();
    if (blocked != null) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(blocked),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      return;
    }
    DocumentReference? addedItemRef;
    try {
      addedItemRef = await addCatalogProductToOrderItem(
        orderRef: widget.orderRef!,
        product: product,
        qty: 1,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'product.select.addError',
                params: {'error': describeFirestoreError(e)}),
          ),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          alignment: AlignmentDirectional(0.0, 0.0)
              .resolve(Directionality.of(context)),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(dialogContext).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: RemarkWidget(
              orderRef: widget.orderRef!,
              orderItemRef: addedItemRef,
            ),
          ),
        );
      },
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(context, 'product.select.addedToCart'),
          style: TextStyle(
            color: FlutterFlowTheme.of(context).primaryText,
          ),
        ),
        duration: const Duration(milliseconds: 4000),
        backgroundColor: FlutterFlowTheme.of(context).secondary,
      ),
    );
  }

  Widget _buildProductSelectionGrid(
    BuildContext context,
    List<ProductRecord> products,
  ) {
    const gridRows = 2;
    const crossAxisSpacing = 8.0;
    const mainAxisSpacing = 8.0;
    const itemWidth = 152.0;
    const itemHeight = 196.0;
    final gridHeight =
        gridRows * itemHeight + (gridRows - 1) * crossAxisSpacing;

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridRows,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: itemHeight / itemWidth,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _buildProductGridCard(context, products[index]);
        },
      ),
    );
  }

  Widget _buildProductGridCard(BuildContext context, ProductRecord product) {
    final theme = FlutterFlowTheme.of(context);
    final priceText = formatNumber(
      product.price,
      formatType: FormatType.decimal,
      decimalType: DecimalType.automatic,
      currency: '',
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: theme.alternate.withValues(alpha: 0.25),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return buildZoomableProductImage(
                    context: context,
                    imageUrl: productImageFromRecord(product),
                    productRef: product.reference,
                    title: product.name,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.contain,
                    placeholderIcon: Icons.local_florist_outlined,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.labelSmall,
            ),
          ),
          if (product.sku.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                product.sku,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelSmall.override(
                  fontSize: 11,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 2),
            child: Text(
              '\$$priceText',
              style: theme.labelMedium.override(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: FFButtonWidget(
              onPressed: () => _addCatalogProductToOrder(context, product),
              text: tr(context, 'common.add'),
              options: FFButtonOptions(
                width: double.infinity,
                height: 32,
                color: theme.primary,
                textStyle: theme.titleSmall.override(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
