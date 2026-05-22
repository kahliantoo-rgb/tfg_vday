import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/structs/index.dart';
import 'package:tfg_vday/actions/library_param_actions.dart'
    as default_library_actions;

class FFLibraryValues {
  static FFLibraryValues _instance = FFLibraryValues._internal();

  factory FFLibraryValues() {
    return _instance;
  }

  FFLibraryValues._internal();

  static void reset() {
    _instance = FFLibraryValues._internal();
  }

  OrderStatus? selectedStatus = OrderStatus.pending;
  Future Function(
    BuildContext context, {
    required DocumentReference? orderRefs,
  }) selectedOrderRefs = default_library_actions.selectedOrderRefs;
}
