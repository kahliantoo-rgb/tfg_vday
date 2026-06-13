import '/flutter_flow/flutter_flow_util.dart';
import 'driver_assignments_page_widget.dart' show DriverAssignmentsPageWidget;
import 'package:flutter/material.dart';
import '/flutter_flow/form_field_controller.dart';

class DriverAssignmentsPageModel
    extends FlutterFlowModel<DriverAssignmentsPageWidget> {
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];

  DateTime? filterStartDate;
  DateTime? filterEndDate;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
