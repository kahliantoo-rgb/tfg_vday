import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'orderlist_widget.dart' show OrderlistWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OrderlistModel extends FlutterFlowModel<OrderlistWidget> {
  ///  Local state fields for this page.

  OrderStatus? selectedStatus = OrderStatus.pending;

  DateTime? startDate;

  DateTime? endDate;

  OrderStatus? actioncompleted = OrderStatus.completed;

  OrderStatus? startprocess = OrderStatus.processing;

  List<DocumentReference> checkedOrders = [];
  void addToCheckedOrders(DocumentReference item) => checkedOrders.add(item);
  void removeFromCheckedOrders(DocumentReference item) =>
      checkedOrders.remove(item);
  void removeAtIndexFromCheckedOrders(int index) =>
      checkedOrders.removeAt(index);
  void insertAtIndexInCheckedOrders(int index, DocumentReference item) =>
      checkedOrders.insert(index, item);
  void updateCheckedOrdersAtIndex(
          int index, Function(DocumentReference) updateFn) =>
      checkedOrders[index] = updateFn(checkedOrders[index]);

  String selectedstatusstring = 'all\n';

  String ordersearch = 'TFG';

  ///  State fields for stateful widgets in this page.

  DateTime? datePicked1;
  DateTime? datePicked2;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  List<OrdersRecord>? ordordeitem;
  // Stores action output result for [Custom Action - exportOrdersToCsv] action in Button widget.
  FFUploadedFile? cSv;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  List<OrderItemRecord>? fullitemlist;
  // Stores action output result for [Custom Action - exportOrderItemsFinalCsv] action in Button widget.
  FFUploadedFile? fulllist;
  // State field(s) for Checkbox widget.
  Map<OrdersRecord, bool> checkboxValueMap = {};
  List<OrdersRecord> get checkboxCheckedItems =>
      checkboxValueMap.entries.where((e) => e.value).map((e) => e.key).toList();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
