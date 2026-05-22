import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'productcreate_widget.dart' show ProductcreateWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProductcreateModel extends FlutterFlowModel<ProductcreateWidget> {
  ///  Local state fields for this page.

  FFUploadedFile? pic;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for productName widget.
  FocusNode? productNameFocusNode;
  TextEditingController? productNameTextController;
  String? Function(BuildContext, String?)? productNameTextControllerValidator;
  String? _productNameTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Please enter the patients full name.';
    }

    return null;
  }

  // State field(s) for skU widget.
  FocusNode? skUFocusNode;
  TextEditingController? skUTextController;
  String? Function(BuildContext, String?)? skUTextControllerValidator;
  String? _skUTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Please enter an age for the patient.';
    }

    return null;
  }

  // State field(s) for Price widget.
  FocusNode? priceFocusNode;
  TextEditingController? priceTextController;
  String? Function(BuildContext, String?)? priceTextControllerValidator;
  String? _priceTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Field is required';
    }

    return null;
  }

  bool isDataUploading_productimage = false;
  FFUploadedFile uploadedLocalFile_productimage =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_productimage = '';

  // State field(s) for Switch widget.
  bool? switchValue;
  // State field(s) for SKU widget.
  String? skuValue;
  FormFieldController<String>? skuValueController;

  @override
  void initState(BuildContext context) {
    productNameTextControllerValidator = _productNameTextControllerValidator;
    skUTextControllerValidator = _skUTextControllerValidator;
    priceTextControllerValidator = _priceTextControllerValidator;
  }

  @override
  void dispose() {
    productNameFocusNode?.dispose();
    productNameTextController?.dispose();

    skUFocusNode?.dispose();
    skUTextController?.dispose();

    priceFocusNode?.dispose();
    priceTextController?.dispose();
  }
}
