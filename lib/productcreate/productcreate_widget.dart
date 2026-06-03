import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/nav/nav.dart';
import '/backend/backend.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'productcreate_model.dart';
export 'productcreate_model.dart';

class ProductcreateWidget extends StatefulWidget {
  const ProductcreateWidget({
    super.key,
    this.productRef,
  });

  final DocumentReference? productRef;

  static String routeName = 'Productcreate';
  static String routePath = '/productcreate';

  @override
  State<ProductcreateWidget> createState() => _ProductcreateWidgetState();
}

class _ProductcreateWidgetState extends State<ProductcreateWidget> {
  late ProductcreateModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String? _hydratedProductId;
  String _previewImageUrl = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductcreateModel());

    _model.productNameTextController ??= TextEditingController();
    _model.productNameFocusNode ??= FocusNode();
    _model.productNameFocusNode!.addListener(() => safeSetState(() {}));
    _model.skUTextController ??= TextEditingController();
    _model.skUFocusNode ??= FocusNode();
    _model.skUFocusNode!.addListener(() => safeSetState(() {}));
    _model.priceTextController ??= TextEditingController();
    _model.priceFocusNode ??= FocusNode();
    _model.priceFocusNode!.addListener(() => safeSetState(() {}));
    _model.switchValue = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  void _hydrateFromProduct(ProductRecord record) {
    if (_hydratedProductId == record.reference.id) {
      return;
    }
    _hydratedProductId = record.reference.id;
    _model.productNameTextController?.text = record.name;
    _model.skUTextController?.text = record.sku;
    _model.priceTextController?.text = record.price.toString();
    _model.switchValue = record.isActive;
    _previewImageUrl = record.image;
    if (record.category.isNotEmpty) {
      _model.skuValue = record.category;
      _model.skuValueController ??= FormFieldController<String>(record.category);
      _model.skuValueController?.value = record.category;
    }
  }

  Future<void> _handleUploadPhoto(DocumentReference? productRef) async {
    if (productRef != null) {
      safeSetState(() => _model.isDataUploading_productimage = true);
      try {
        final url = await pickAndUploadProductImage(
          context: context,
          productRef: productRef,
        );
        if (url != null) {
          safeSetState(() => _previewImageUrl = url);
        }
      } finally {
        safeSetState(() => _model.isDataUploading_productimage = false);
      }
      return;
    }

    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );
    if (selectedMedia == null ||
        selectedMedia.isEmpty ||
        !selectedMedia.every((m) => validateFileFormat(m.storagePath, context))) {
      return;
    }
    safeSetState(() => _model.isDataUploading_productimage = true);
    try {
      final media = selectedMedia.first;
      final path =
          'product_images/drafts/${DateTime.now().millisecondsSinceEpoch}_${media.storagePath.split('/').last}';
      final downloadUrl = await uploadData(path, media.bytes);
      if (downloadUrl != null) {
        safeSetState(() {
          _model.uploadedLocalFile_productimage = FFUploadedFile(
            name: media.storagePath.split('/').last,
            bytes: media.bytes,
          );
          _model.uploadedFileUrl_productimage = downloadUrl;
          _previewImageUrl = downloadUrl;
        });
      }
    } finally {
      safeSetState(() => _model.isDataUploading_productimage = false);
    }
  }

  Future<void> _saveProduct(ProductRecord? existing) async {
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }
    if (!ensureActiveCompanyForWrite(context)) {
      return;
    }

    final price = double.tryParse(_model.priceTextController.text.trim());
    final imageUrl = _previewImageUrl.isNotEmpty
        ? _previewImageUrl
        : (_model.uploadedFileUrl_productimage.isNotEmpty
            ? _model.uploadedFileUrl_productimage
            : '');

    final ref = existing?.reference ?? ProductRecord.collection.doc();
    final payload = createTenantProductRecordData(
      name: _model.productNameTextController.text.trim(),
      price: price,
      image: imageUrl,
      sku: _model.skUTextController.text.trim(),
      isActive: _model.switchValue,
      category: _model.skuValue,
    );

    if (existing == null) {
      await ref.set(payload);
      if (_model.uploadedLocalFile_productimage.bytes != null &&
          _model.uploadedLocalFile_productimage.bytes!.isNotEmpty &&
          !isUsableImageUrl(imageUrl)) {
        final filename = _model.uploadedLocalFile_productimage.name ?? 'photo.jpg';
        final url = await uploadData(
          productImageStoragePath(ref.id, filename),
          _model.uploadedLocalFile_productimage.bytes!,
        );
        if (url != null) {
          await ref.update(createProductRecordData(image: url));
        }
      }
    } else {
      await ref.update(createProductRecordData(
        name: _model.productNameTextController.text.trim(),
        price: price,
        image: imageUrl.isNotEmpty ? imageUrl : existing.image,
        sku: _model.skUTextController.text.trim(),
        isActive: _model.switchValue,
        category: _model.skuValue,
      ));
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existing == null ? 'Product created' : 'Product updated'),
        backgroundColor: FlutterFlowTheme.of(context).secondary,
      ),
    );
    context.pushNamed(ProductlistWidget.routeName);
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = AppStateNotifier.instance.userRole;
    final isEdit = widget.productRef != null;
    if (!canCreateProducts(role) || (isEdit && !canEditProducts(role))) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.safePop(),
          ),
          title: const Text('Product'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              isEdit
                  ? 'Only administrators can edit products.'
                  : 'You do not have permission to create products.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.productRef != null ? 'Edit Product' : 'Create Product',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      font: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        fontStyle: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .fontStyle,
                      ),
                      color: Color(0xFF15161E),
                      fontSize: 24.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                    ),
              ),
              Text(
                'Please fill out the form below to continue.',
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      font: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelMedium.fontStyle,
                      ),
                      color: Color(0xFF606A85),
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    ),
              ),
            ].divide(SizedBox(height: 4.0)),
          ),
          actions: [
            const HomeNavIconButton(),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 12.0, 8.0),
              child: FlutterFlowIconButton(
                borderColor: Color(0xFFE5E7EB),
                borderRadius: 12.0,
                borderWidth: 1.0,
                buttonSize: 40.0,
                fillColor: Colors.white,
                icon: Icon(
                  Icons.close_rounded,
                  color: Color(0xFF15161E),
                  size: 24.0,
                ),
                onPressed: () async {
                  context.safePop();
                },
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: StreamBuilder<List<ProductRecord>>(
            stream: widget.productRef != null
                ? ProductRecord.getDocument(widget.productRef!)
                    .map((record) => [record])
                : Stream.value(const <ProductRecord>[]),
            builder: (context, snapshot) {
              if (widget.productRef != null && !snapshot.hasData) {
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
              final formProductRecord =
                  snapshot.data != null && snapshot.data!.isNotEmpty
                      ? snapshot.data!.first
                      : null;

              if (formProductRecord != null) {
                _hydrateFromProduct(formProductRecord);
              }

              return Form(
                key: _model.formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Align(
                              alignment: AlignmentDirectional(0.0, -1.0),
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: 770.0,
                                ),
                                decoration: BoxDecoration(),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 12.0, 16.0, 0.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller:
                                            _model.productNameTextController,
                                        focusNode: _model.productNameFocusNode,
                                        autofocus: true,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          labelText: 'Product Name',
                                          labelStyle: FlutterFlowTheme.of(
                                                  context)
                                              .headlineMedium
                                              .override(
                                                font: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .headlineMedium
                                                          .fontStyle,
                                                ),
                                                color: Color(0xFF606A85),
                                                fontSize: 24.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .headlineMedium
                                                        .fontStyle,
                                              ),
                                          hintStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontStyle,
                                                ),
                                                color: Color(0xFF606A85),
                                                fontSize: 14.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                          errorStyle: FlutterFlowTheme.of(
                                                  context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.figtree(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color: Color(0xFFFF5963),
                                                fontSize: 12.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFE5E7EB),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFF6F61EF),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFFF5963),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFFF5963),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          filled: true,
                                          fillColor: (_model
                                                      .productNameFocusNode
                                                      ?.hasFocus ??
                                                  false)
                                              ? Color(0x4D9489F5)
                                              : Colors.white,
                                          contentPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 20.0, 16.0, 20.0),
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .headlineMedium
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF15161E),
                                              fontSize: 24.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .headlineMedium
                                                      .fontStyle,
                                            ),
                                        cursorColor: Color(0xFF6F61EF),
                                        validator: _model
                                            .productNameTextControllerValidator
                                            .asValidator(context),
                                        inputFormatters: [
                                          if (!isAndroid && !isiOS)
                                            TextInputFormatter.withFunction(
                                                (oldValue, newValue) {
                                              return TextEditingValue(
                                                selection: newValue.selection,
                                                text: newValue.text
                                                    .toCapitalization(
                                                        TextCapitalization
                                                            .words),
                                              );
                                            }),
                                        ],
                                      ),
                                      TextFormField(
                                        controller: _model.skUTextController,
                                        focusNode: _model.skUFocusNode,
                                        autofocus: true,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          labelText: 'SKU',
                                          labelStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelLarge
                                              .override(
                                                font: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelLarge
                                                          .fontStyle,
                                                ),
                                                color: Color(0xFF606A85),
                                                fontSize: 16.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelLarge
                                                        .fontStyle,
                                              ),
                                          hintStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontStyle,
                                                ),
                                                color: Color(0xFF606A85),
                                                fontSize: 14.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                          errorStyle: FlutterFlowTheme.of(
                                                  context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.figtree(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color: Color(0xFFFF5963),
                                                fontSize: 12.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFE5E7EB),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFF6F61EF),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFFF5963),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFFF5963),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          filled: true,
                                          fillColor:
                                              (_model.skUFocusNode?.hasFocus ??
                                                      false)
                                                  ? Color(0x4D9489F5)
                                                  : Colors.white,
                                          contentPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 20.0, 16.0, 20.0),
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyLarge
                                            .override(
                                              font: GoogleFonts.figtree(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF15161E),
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                        cursorColor: Color(0xFF6F61EF),
                                        validator: _model
                                            .skUTextControllerValidator
                                            .asValidator(context),
                                        inputFormatters: [
                                          if (!isAndroid && !isiOS)
                                            TextInputFormatter.withFunction(
                                                (oldValue, newValue) {
                                              return TextEditingValue(
                                                selection: newValue.selection,
                                                text: newValue.text
                                                    .toCapitalization(
                                                        TextCapitalization
                                                            .words),
                                              );
                                            }),
                                        ],
                                      ),
                                      TextFormField(
                                        controller: _model.priceTextController,
                                        focusNode: _model.priceFocusNode,
                                        autofocus: true,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          labelText: 'Price',
                                          labelStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelLarge
                                              .override(
                                                font: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelLarge
                                                          .fontStyle,
                                                ),
                                                color: Color(0xFF606A85),
                                                fontSize: 16.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelLarge
                                                        .fontStyle,
                                              ),
                                          hintStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontStyle,
                                                ),
                                                color: Color(0xFF606A85),
                                                fontSize: 14.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                          errorStyle: FlutterFlowTheme.of(
                                                  context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.figtree(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color: Color(0xFFFF5963),
                                                fontSize: 12.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFE5E7EB),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFF6F61EF),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFFF5963),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFFF5963),
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          filled: true,
                                          fillColor: (_model.priceFocusNode
                                                      ?.hasFocus ??
                                                  false)
                                              ? Color(0x4D9489F5)
                                              : Colors.white,
                                          contentPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 20.0, 16.0, 20.0),
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyLarge
                                            .override(
                                              font: GoogleFonts.figtree(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF15161E),
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                        cursorColor: Color(0xFF6F61EF),
                                        validator: _model
                                            .priceTextControllerValidator
                                            .asValidator(context),
                                        keyboardType: const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d{0,2}'),
                                          ),
                                        ],
                                      ),
                                      if (isUsableImageUrl(_previewImageUrl))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.network(
                                              _previewImageUrl,
                                              height: 120.0,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const SizedBox.shrink(),
                                            ),
                                          ),
                                        ),
                                      FFButtonWidget(
                                        onPressed: _model
                                                .isDataUploading_productimage
                                            ? null
                                            : () => _handleUploadPhoto(
                                                  formProductRecord?.reference,
                                                ),
                                        text: _model.isDataUploading_productimage
                                            ? 'Uploading...'
                                            : 'Upload Photo',
                                        icon: const Icon(
                                          Icons.upload_outlined,
                                          size: 18.0,
                                          color: Colors.white,
                                        ),
                                        options: FFButtonOptions(
                                          width: double.infinity,
                                          height: 44.0,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              blurRadius: 4.0,
                                              color: Color(0x33000000),
                                              offset: Offset(
                                                0.0,
                                                2.0,
                                              ),
                                            )
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Is Active ',
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                            Switch.adaptive(
                                              value: _model.switchValue ?? true,
                                              onChanged: (newValue) async {
                                                safeSetState(() =>
                                                    _model.switchValue =
                                                        newValue);
                                                if (formProductRecord != null) {
                                                  await updateProductIsActive(
                                                    formProductRecord.reference,
                                                    newValue,
                                                  );
                                                }
                                              },
                                              activeColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              activeTrackColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              inactiveTrackColor:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              inactiveThumbColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                          ],
                                        ),
                                      ),
                                      FlutterFlowDropDown<String>(
                                        controller: _model
                                                .skuValueController ??=
                                            FormFieldController<String>(null),
                                        options: [
                                          'Hand Bouquet',
                                          'Wreath',
                                          'Opening Stand',
                                          'Table arrangement',
                                          'AdHoc'
                                        ],
                                        onChanged: (val) => safeSetState(
                                            () => _model.skuValue = val),
                                        width: 386.6,
                                        height: 40.0,
                                        textStyle: FlutterFlowTheme.of(context)
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
                                        hintText: 'Category',
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          size: 24.0,
                                        ),
                                        fillColor: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        elevation: 2.0,
                                        borderColor: Colors.transparent,
                                        borderWidth: 0.0,
                                        borderRadius: 8.0,
                                        margin: EdgeInsets.all(0.0),
                                        hidesUnderline: true,
                                        isOverButton: false,
                                        isSearchable: false,
                                        isMultiSelect: false,
                                      ),
                                    ]
                                        .divide(SizedBox(height: 12.0))
                                        .addToEnd(SizedBox(height: 32.0)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: 770.0,
                      ),
                      decoration: BoxDecoration(),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 12.0, 16.0, 12.0),
                        child: FFButtonWidget(
                          onPressed: () async {
                            await _saveProduct(formProductRecord);
                          },
                          text: formProductRecord != null ? 'Save' : 'Create',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 48.0,
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 0.0, 24.0, 0.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: Color(0xFF6F61EF),
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  font: GoogleFonts.figtree(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                            elevation: 3.0,
                            borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
