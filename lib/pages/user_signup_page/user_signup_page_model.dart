import 'dart:typed_data';

import '/flutter_flow/flutter_flow_util.dart';
import 'user_signup_page_widget.dart' show UserSignupPageWidget;
import 'package:flutter/material.dart';
class UserSignupPageModel extends FlutterFlowModel<UserSignupPageWidget> {
  final formKey = GlobalKey<FormState>();

  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  FocusNode? phoneFocusNode;
  TextEditingController? phoneTextController;
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;

  FocusNode? companyNameFocusNode;
  TextEditingController? companyNameTextController;
  FocusNode? companyUenFocusNode;
  TextEditingController? companyUenTextController;
  FocusNode? companyAddressFocusNode;
  TextEditingController? companyAddressTextController;
  FocusNode? companyPhoneFocusNode;
  TextEditingController? companyPhoneTextController;
  FocusNode? companyEmailFocusNode;
  TextEditingController? companyEmailTextController;

  DateTime? birthday;
  bool isCompanyAccount = false;
  bool saving = false;
  bool uploadingLogo = false;
  String? pickedLogoFilename;
  Uint8List? pickedLogoBytes;
  String? logoPreviewPath;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();
    phoneFocusNode?.dispose();
    phoneTextController?.dispose();
    emailFocusNode?.dispose();
    emailTextController?.dispose();
    companyNameFocusNode?.dispose();
    companyNameTextController?.dispose();
    companyUenFocusNode?.dispose();
    companyUenTextController?.dispose();
    companyAddressFocusNode?.dispose();
    companyAddressTextController?.dispose();
    companyPhoneFocusNode?.dispose();
    companyPhoneTextController?.dispose();
    companyEmailFocusNode?.dispose();
    companyEmailTextController?.dispose();
  }
}
