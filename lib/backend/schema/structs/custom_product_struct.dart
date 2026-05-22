// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CustomProductStruct extends FFFirebaseStruct {
  CustomProductStruct({
    String? name,
    double? price,
    int? qty,
    String? remark,
    String? type,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _name = name,
        _price = price,
        _qty = qty,
        _remark = remark,
        _type = type,
        super(firestoreUtilData);

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "price" field.
  double? _price;
  double get price => _price ?? 0.0;
  set price(double? val) => _price = val;

  void incrementPrice(double amount) => price = price + amount;

  bool hasPrice() => _price != null;

  // "qty" field.
  int? _qty;
  int get qty => _qty ?? 0;
  set qty(int? val) => _qty = val;

  void incrementQty(int amount) => qty = qty + amount;

  bool hasQty() => _qty != null;

  // "remark" field.
  String? _remark;
  String get remark => _remark ?? '';
  set remark(String? val) => _remark = val;

  bool hasRemark() => _remark != null;

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  set type(String? val) => _type = val;

  bool hasType() => _type != null;

  static CustomProductStruct fromMap(Map<String, dynamic> data) =>
      CustomProductStruct(
        name: data['name'] as String?,
        price: castToType<double>(data['price']),
        qty: castToType<int>(data['qty']),
        remark: data['remark'] as String?,
        type: data['type'] as String?,
      );

  static CustomProductStruct? maybeFromMap(dynamic data) => data is Map
      ? CustomProductStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'name': _name,
        'price': _price,
        'qty': _qty,
        'remark': _remark,
        'type': _type,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'price': serializeParam(
          _price,
          ParamType.double,
        ),
        'qty': serializeParam(
          _qty,
          ParamType.int,
        ),
        'remark': serializeParam(
          _remark,
          ParamType.String,
        ),
        'type': serializeParam(
          _type,
          ParamType.String,
        ),
      }.withoutNulls;

  static CustomProductStruct fromSerializableMap(Map<String, dynamic> data) =>
      CustomProductStruct(
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        price: deserializeParam(
          data['price'],
          ParamType.double,
          false,
        ),
        qty: deserializeParam(
          data['qty'],
          ParamType.int,
          false,
        ),
        remark: deserializeParam(
          data['remark'],
          ParamType.String,
          false,
        ),
        type: deserializeParam(
          data['type'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'CustomProductStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is CustomProductStruct &&
        name == other.name &&
        price == other.price &&
        qty == other.qty &&
        remark == other.remark &&
        type == other.type;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([name, price, qty, remark, type]);
}

CustomProductStruct createCustomProductStruct({
  String? name,
  double? price,
  int? qty,
  String? remark,
  String? type,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    CustomProductStruct(
      name: name,
      price: price,
      qty: qty,
      remark: remark,
      type: type,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

CustomProductStruct? updateCustomProductStruct(
  CustomProductStruct? customProduct, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    customProduct
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addCustomProductStructData(
  Map<String, dynamic> firestoreData,
  CustomProductStruct? customProduct,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (customProduct == null) {
    return;
  }
  if (customProduct.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && customProduct.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final customProductData =
      getCustomProductFirestoreData(customProduct, forFieldValue);
  final nestedData =
      customProductData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = customProduct.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getCustomProductFirestoreData(
  CustomProductStruct? customProduct, [
  bool forFieldValue = false,
]) {
  if (customProduct == null) {
    return {};
  }
  final firestoreData = mapToFirestore(customProduct.toMap());

  // Add any Firestore field values
  customProduct.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getCustomProductListFirestoreData(
  List<CustomProductStruct>? customProducts,
) =>
    customProducts
        ?.map((e) => getCustomProductFirestoreData(e, true))
        .toList() ??
    [];
