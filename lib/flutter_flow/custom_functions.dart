import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/library_values.dart';

String? newCustomFunction(String postalCode) {
  if (postalCode.isEmpty) {
    return "Unknown";
  }
  final sector = int.tryParse(postalCode.substring(0, 2));

  if (sector == null) {
    return 'Unknown';
  }

  // CENTRAL
  if (sector >= 1 && sector <= 33) {
    return 'Central';
  }

  // EAST
  else if ((sector >= 34 && sector <= 37) ||
      (sector >= 42 && sector <= 48) ||
      (sector >= 49 && sector <= 52)) {
    return 'East';
  }

  // NORTH-EAST
  else if ((sector >= 53 && sector <= 56) || sector == 82) {
    return 'North-East';
  }

  // NORTH
  else if ((sector >= 70 && sector <= 73) || (sector >= 75 && sector <= 77)) {
    return 'North';
  }

  // WEST
  else if ((sector >= 60 && sector <= 69) || (sector >= 11 && sector <= 13)) {
    return 'West';
  }

  return 'Unknown';
}

double newCustomFunction2(
  double prices,
  int qty,
) {
  return prices * qty;
}

double calculatetax(double subtotal) {
  return subtotal * 0.085;
}

double newCustomFunction3(
  double subtotal,
  double taxrate,
) {
  return subtotal * (1 + taxrate);
}

double decreaseQtysubtotal(
  double price,
  int qty,
) {
  return price * (qty - 1);
}

double increaseQtySubtotal(
  double price,
  int qty,
) {
  return price * (qty + 1);
}

int calculateTotalItem(int qty) {
  return qty;
}

double calculationTotal(
  List<double> price,
  List<int> qty,
) {
  if (price.isEmpty || qty.isEmpty) {
    return 0;
  }

  final int len = price.length < qty.length ? price.length : qty.length;

  double total = 0;

  for (int i = 0; i < len; i++) {
    total += price[i] * qty[i];
  }

  return total;
}
