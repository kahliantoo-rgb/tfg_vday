import '/flutter_flow/flutter_flow_util.dart';
import 'invoice_list_page_widget.dart' show InvoiceListPageWidget;
import 'package:flutter/material.dart';

class InvoiceListPageModel extends FlutterFlowModel<InvoiceListPageWidget> {
  TextEditingController? invoiceNumberController;
  FocusNode? invoiceNumberFocusNode;

  TextEditingController? customerController;
  FocusNode? customerFocusNode;

  DateTime? selectedMonth;
  String selectedCreditTerm = '';
  bool includeVoided = false;

  @override
  void initState(BuildContext context) {
    invoiceNumberController ??= TextEditingController();
    invoiceNumberFocusNode ??= FocusNode();
    customerController ??= TextEditingController();
    customerFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    invoiceNumberFocusNode?.dispose();
    invoiceNumberController?.dispose();
    customerFocusNode?.dispose();
    customerController?.dispose();
  }
}
