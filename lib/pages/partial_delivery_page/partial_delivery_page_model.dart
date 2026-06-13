import '/flutter_flow/flutter_flow_util.dart';
import 'partial_delivery_page_widget.dart' show PartialDeliveryPageWidget;
import 'package:flutter/material.dart';

class PartialDeliveryPageModel extends FlutterFlowModel<PartialDeliveryPageWidget> {
  final deliverNowByItemId = <String, int>{};
  DateTime? nextDeliveryDate;
  bool submitting = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
