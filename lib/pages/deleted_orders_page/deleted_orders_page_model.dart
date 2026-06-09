import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'deleted_orders_page_widget.dart' show DeletedOrdersPageWidget;

class DeletedOrdersPageModel extends FlutterFlowModel<DeletedOrdersPageWidget> {
  TextEditingController? searchController;
  FocusNode? searchFocusNode;

  DateTime? deletedFrom;
  DateTime? deletedTo;
  String deletedByFilter = 'All';
  String statusFilter = 'All';
  int pageIndex = 0;

  @override
  void initState(BuildContext context) {
    searchController ??= TextEditingController();
    searchFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    searchController?.dispose();
    searchFocusNode?.dispose();
  }
}
