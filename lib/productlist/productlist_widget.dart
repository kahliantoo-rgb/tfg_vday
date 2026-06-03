import '/auth/role_helpers.dart';
import '/components/home_nav_button.dart';
import '/backend/backend.dart';
import '/flutter_flow/nav/nav.dart';
import '/backend/tenant_query_helpers.dart';
import '/components/product_list_item_editor.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/index.dart';
import 'productlist_model.dart';
export 'productlist_model.dart';

/// Product list with inline price, active status, and photo upload.
class ProductlistWidget extends StatefulWidget {
  const ProductlistWidget({
    super.key,
    this.productRef,
  });

  final DocumentReference? productRef;

  static String routeName = 'Productlist';
  static String routePath = '/productlist';

  @override
  State<ProductlistWidget> createState() => _ProductlistWidgetState();
}

class _ProductlistWidgetState extends State<ProductlistWidget> {
  late ProductlistModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductlistModel());

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
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 0.0, 0.0),
            child: Text(
              'Product',
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    font: GoogleFonts.interTight(),
                    color: Colors.white,
                    fontSize: 22.0,
                  ),
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
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Product List',
                          style: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                        if (canCreateProducts(
                            AppStateNotifier.instance.userRole))
                          FlutterFlowIconButton(
                            borderRadius: 20.0,
                            buttonSize: 40.0,
                            icon: Icon(
                              Icons.add_rounded,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 24.0,
                            ),
                            onPressed: () async {
                              context.pushNamed(ProductcreateWidget.routeName);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ProductRecord>>(
                  stream: queryTenantProductRecord().map((products) {
                    final sorted = [...products];
                    sorted.sort(
                      (a, b) => a.name
                          .toLowerCase()
                          .compareTo(b.name.toLowerCase()),
                    );
                    return sorted;
                  }),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            FlutterFlowTheme.of(context).primary,
                          ),
                        ),
                      );
                    }
                    final products = snapshot.data!;
                    if (products.isEmpty) {
                      return const Center(child: Text('No products yet'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        if (canEditProducts(
                            AppStateNotifier.instance.userRole)) {
                          return ProductListItemEditor(
                            key: ValueKey(product.reference.path),
                            product: product,
                          );
                        }
                        return ListTile(
                          key: ValueKey(product.reference.path),
                          title: Text(product.name),
                          subtitle: Text(
                            '\$${product.price.toStringAsFixed(2)} · '
                            '${product.isActive ? "Active" : "Inactive"}',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
