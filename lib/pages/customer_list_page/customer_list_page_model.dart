import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'customer_list_page_widget.dart' show CustomerListPageWidget;

class CustomerListPageModel extends FlutterFlowModel<CustomerListPageWidget> {
  TextEditingController? searchController;
  FocusNode? searchFocusNode;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    searchController?.dispose();
    searchFocusNode?.dispose();
  }
}
