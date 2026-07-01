import 'package:flutter/material.dart';

import '/backend/customer_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'customer_create_form_widget.dart' show CustomerCreateFormWidget;

class CustomerCreateFormModel extends FlutterFlowModel<CustomerCreateFormWidget> {
  final formKey = GlobalKey<FormState>();
  FocusNode? nameFocusNode;
  TextEditingController? nameController;
  FocusNode? phoneFocusNode;
  TextEditingController? phoneController;
  FocusNode? emailFocusNode;
  TextEditingController? emailController;
  FocusNode? billingAddressFocusNode;
  TextEditingController? billingAddressController;
  FocusNode? uenFocusNode;
  TextEditingController? uenController;
  bool isCreditCustomer = false;
  String? creditTerm;
  DocumentReference? selectedPriceListRef;
  DateTime? birthday;
  bool saving = false;

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? validatePhone(String? value) =>
      validateCustomerPhoneInput(value);

  String? validateEmail(String? value) => validateCustomerEmailInput(value);

  String? validateBillingAddress(String? value) => null;

  String? validateUen(String? value) => null;

  String? validateCreditCustomer() {
    if (isCreditCustomer && (creditTerm == null || creditTerm!.trim().isEmpty)) {
      return 'Select credit terms for credit customers';
    }
    return null;
  }

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameController?.dispose();
    phoneFocusNode?.dispose();
    phoneController?.dispose();
    emailFocusNode?.dispose();
    emailController?.dispose();
    billingAddressFocusNode?.dispose();
    billingAddressController?.dispose();
    uenFocusNode?.dispose();
    uenController?.dispose();
  }
}
