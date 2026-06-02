import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'register_page_widget.dart' show RegisterPageWidget;
import 'package:flutter/material.dart';

class RegisterPageModel extends FlutterFlowModel<RegisterPageWidget> {
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;

  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;

  FocusNode? phoneFocusNode;
  TextEditingController? phoneTextController;

  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;

  FocusNode? confirmPasswordFocusNode;
  TextEditingController? confirmPasswordTextController;
  late bool confirmPasswordVisibility;

  FormFieldController<String>? roleDropDownController;
  String? roleDropDownValue;

  FormFieldController<String>? companyDropDownController;
  String? companyDropDownValue;

  bool isSubmitting = false;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
    confirmPasswordVisibility = false;
  }

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();
    emailFocusNode?.dispose();
    emailTextController?.dispose();
    phoneFocusNode?.dispose();
    phoneTextController?.dispose();
    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
    confirmPasswordFocusNode?.dispose();
    confirmPasswordTextController?.dispose();
  }
}
