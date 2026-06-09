import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class AuditLogPageModel extends FlutterFlowModel {
  String? actionFilter;
  String? entityTypeFilter;
  String? userNameFilter;
  DateTime? startDate;
  DateTime? endDate;
  String searchQuery = '';

  FormFieldController<String>? actionFilterController;
  FormFieldController<String>? entityTypeFilterController;
  FormFieldController<String>? userNameFilterController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    actionFilterController?.dispose();
    entityTypeFilterController?.dispose();
    userNameFilterController?.dispose();
  }
}
