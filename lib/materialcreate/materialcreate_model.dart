import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'materialcreate_widget.dart' show MaterialcreateWidget;
import 'package:flutter/material.dart';

class MaterialcreateModel extends FlutterFlowModel<MaterialcreateWidget> {
  final formKey = GlobalKey<FormState>();

  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;

  FocusNode? skuFocusNode;
  TextEditingController? skuTextController;

  FocusNode? costFocusNode;
  TextEditingController? costTextController;

  String? unitValue;
  FormFieldController<String>? unitValueController;

  bool switchValue = true;
  bool isSubmitting = false;

  @override
  void initState(BuildContext context) {
    nameTextControllerValidator = (context, val) {
      if (val == null || val.trim().isEmpty) {
        return 'Material name is required.';
      }
      return null;
    };
  }

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();
    skuFocusNode?.dispose();
    skuTextController?.dispose();
    costFocusNode?.dispose();
    costTextController?.dispose();
  }
}
