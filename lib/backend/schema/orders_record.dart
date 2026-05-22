import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OrdersRecord extends FirestoreRecord {
  OrdersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "client_name" field.
  String? _clientName;
  String get clientName => _clientName ?? '';
  bool hasClientName() => _clientName != null;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  bool hasAddress() => _address != null;

  // "region" field.
  String? _region;
  String get region => _region ?? '';
  bool hasRegion() => _region != null;

  // "delivery_date" field.
  DateTime? _deliveryDate;
  DateTime? get deliveryDate => _deliveryDate;
  bool hasDeliveryDate() => _deliveryDate != null;

  // "assigned_driver" field.
  DocumentReference? _assignedDriver;
  DocumentReference? get assignedDriver => _assignedDriver;
  bool hasAssignedDriver() => _assignedDriver != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "card_message" field.
  String? _cardMessage;
  String get cardMessage => _cardMessage ?? '';
  bool hasCardMessage() => _cardMessage != null;

  // "Order_Id" field.
  String? _orderId;
  String get orderId => _orderId ?? '';
  bool hasOrderId() => _orderId != null;

  // "autoRegion" field.
  String? _autoRegion;
  String get autoRegion => _autoRegion ?? '';
  bool hasAutoRegion() => _autoRegion != null;

  // "PostalCode" field.
  String? _postalCode;
  String get postalCode => _postalCode ?? '';
  bool hasPostalCode() => _postalCode != null;

  // "Cancel_reason" field.
  String? _cancelReason;
  String get cancelReason => _cancelReason ?? '';
  bool hasCancelReason() => _cancelReason != null;

  // "Cancelled_at" field.
  DateTime? _cancelledAt;
  DateTime? get cancelledAt => _cancelledAt;
  bool hasCancelledAt() => _cancelledAt != null;

  // "delivery_time_slot" field.
  String? _deliveryTimeSlot;
  String get deliveryTimeSlot => _deliveryTimeSlot ?? '';
  bool hasDeliveryTimeSlot() => _deliveryTimeSlot != null;

  // "delivery_time_actual" field.
  DateTime? _deliveryTimeActual;
  DateTime? get deliveryTimeActual => _deliveryTimeActual;
  bool hasDeliveryTimeActual() => _deliveryTimeActual != null;

  // "total" field.
  double? _total;
  double get total => _total ?? 0.0;
  bool hasTotal() => _total != null;

  // "orderType" field.
  String? _orderType;
  String get orderType => _orderType ?? '';
  bool hasOrderType() => _orderType != null;

  // "paymentType" field.
  String? _paymentType;
  String get paymentType => _paymentType ?? '';
  bool hasPaymentType() => _paymentType != null;

  // "status" field.
  OrderStatus? _status;
  OrderStatus? get status => _status;
  bool hasStatus() => _status != null;

  // "customer_phone_number" field.
  String? _customerPhoneNumber;
  String get customerPhoneNumber => _customerPhoneNumber ?? '';
  bool hasCustomerPhoneNumber() => _customerPhoneNumber != null;

  // "ProductSelection" field.
  DocumentReference? _productSelection;
  DocumentReference? get productSelection => _productSelection;
  bool hasProductSelection() => _productSelection != null;

  // "totalAmount" field.
  double? _totalAmount;
  double get totalAmount => _totalAmount ?? 0.0;
  bool hasTotalAmount() => _totalAmount != null;

  // "totalQty" field.
  int? _totalQty;
  int get totalQty => _totalQty ?? 0;
  bool hasTotalQty() => _totalQty != null;

  // "current" field.
  int? _current;
  int get current => _current ?? 0;
  bool hasCurrent() => _current != null;

  // "currentrtl" field.
  int? _currentrtl;
  int get currentrtl => _currentrtl ?? 0;
  bool hasCurrentrtl() => _currentrtl != null;

  // "pickup_delivery" field.
  String? _pickupDelivery;
  String get pickupDelivery => _pickupDelivery ?? '';
  bool hasPickupDelivery() => _pickupDelivery != null;

  // "orderstatus" field.
  String? _orderstatus;
  String get orderstatus => _orderstatus ?? '';
  bool hasOrderstatus() => _orderstatus != null;

  void _initializeFields() {
    _clientName = snapshotData['client_name'] as String?;
    _address = snapshotData['address'] as String?;
    _region = snapshotData['region'] as String?;
    _deliveryDate = snapshotData['delivery_date'] as DateTime?;
    _assignedDriver = snapshotData['assigned_driver'] as DocumentReference?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _cardMessage = snapshotData['card_message'] as String?;
    _orderId = snapshotData['Order_Id'] as String?;
    _autoRegion = snapshotData['autoRegion'] as String?;
    _postalCode = snapshotData['PostalCode'] as String?;
    _cancelReason = snapshotData['Cancel_reason'] as String?;
    _cancelledAt = snapshotData['Cancelled_at'] as DateTime?;
    _deliveryTimeSlot = snapshotData['delivery_time_slot'] as String?;
    _deliveryTimeActual = snapshotData['delivery_time_actual'] as DateTime?;
    _total = castToType<double>(snapshotData['total']);
    _orderType = snapshotData['orderType'] as String?;
    _paymentType = snapshotData['paymentType'] as String?;
    _status = snapshotData['status'] is OrderStatus
        ? snapshotData['status']
        : deserializeEnum<OrderStatus>(snapshotData['status']);
    _customerPhoneNumber = snapshotData['customer_phone_number'] as String?;
    _productSelection = snapshotData['ProductSelection'] as DocumentReference?;
    _totalAmount = castToType<double>(snapshotData['totalAmount']);
    _totalQty = castToType<int>(snapshotData['totalQty']);
    _current = castToType<int>(snapshotData['current']);
    _currentrtl = castToType<int>(snapshotData['currentrtl']);
    _pickupDelivery = snapshotData['pickup_delivery'] as String?;
    _orderstatus = snapshotData['orderstatus'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('orders');

  static Stream<OrdersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => OrdersRecord.fromSnapshot(s));

  static Future<OrdersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => OrdersRecord.fromSnapshot(s));

  static OrdersRecord fromSnapshot(DocumentSnapshot snapshot) => OrdersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static OrdersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      OrdersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'OrdersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is OrdersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createOrdersRecordData({
  String? clientName,
  String? address,
  String? region,
  DateTime? deliveryDate,
  DocumentReference? assignedDriver,
  DateTime? createdTime,
  String? cardMessage,
  String? orderId,
  String? autoRegion,
  String? postalCode,
  String? cancelReason,
  DateTime? cancelledAt,
  String? deliveryTimeSlot,
  DateTime? deliveryTimeActual,
  double? total,
  String? orderType,
  String? paymentType,
  OrderStatus? status,
  String? customerPhoneNumber,
  DocumentReference? productSelection,
  double? totalAmount,
  int? totalQty,
  int? current,
  int? currentrtl,
  String? pickupDelivery,
  String? orderstatus,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'client_name': clientName,
      'address': address,
      'region': region,
      'delivery_date': deliveryDate,
      'assigned_driver': assignedDriver,
      'created_time': createdTime,
      'card_message': cardMessage,
      'Order_Id': orderId,
      'autoRegion': autoRegion,
      'PostalCode': postalCode,
      'Cancel_reason': cancelReason,
      'Cancelled_at': cancelledAt,
      'delivery_time_slot': deliveryTimeSlot,
      'delivery_time_actual': deliveryTimeActual,
      'total': total,
      'orderType': orderType,
      'paymentType': paymentType,
      'status': status,
      'customer_phone_number': customerPhoneNumber,
      'ProductSelection': productSelection,
      'totalAmount': totalAmount,
      'totalQty': totalQty,
      'current': current,
      'currentrtl': currentrtl,
      'pickup_delivery': pickupDelivery,
      'orderstatus': orderstatus,
    }.withoutNulls,
  );

  return firestoreData;
}

class OrdersRecordDocumentEquality implements Equality<OrdersRecord> {
  const OrdersRecordDocumentEquality();

  @override
  bool equals(OrdersRecord? e1, OrdersRecord? e2) {
    return e1?.clientName == e2?.clientName &&
        e1?.address == e2?.address &&
        e1?.region == e2?.region &&
        e1?.deliveryDate == e2?.deliveryDate &&
        e1?.assignedDriver == e2?.assignedDriver &&
        e1?.createdTime == e2?.createdTime &&
        e1?.cardMessage == e2?.cardMessage &&
        e1?.orderId == e2?.orderId &&
        e1?.autoRegion == e2?.autoRegion &&
        e1?.postalCode == e2?.postalCode &&
        e1?.cancelReason == e2?.cancelReason &&
        e1?.cancelledAt == e2?.cancelledAt &&
        e1?.deliveryTimeSlot == e2?.deliveryTimeSlot &&
        e1?.deliveryTimeActual == e2?.deliveryTimeActual &&
        e1?.total == e2?.total &&
        e1?.orderType == e2?.orderType &&
        e1?.paymentType == e2?.paymentType &&
        e1?.status == e2?.status &&
        e1?.customerPhoneNumber == e2?.customerPhoneNumber &&
        e1?.productSelection == e2?.productSelection &&
        e1?.totalAmount == e2?.totalAmount &&
        e1?.totalQty == e2?.totalQty &&
        e1?.current == e2?.current &&
        e1?.currentrtl == e2?.currentrtl &&
        e1?.pickupDelivery == e2?.pickupDelivery &&
        e1?.orderstatus == e2?.orderstatus;
  }

  @override
  int hash(OrdersRecord? e) => const ListEquality().hash([
        e?.clientName,
        e?.address,
        e?.region,
        e?.deliveryDate,
        e?.assignedDriver,
        e?.createdTime,
        e?.cardMessage,
        e?.orderId,
        e?.autoRegion,
        e?.postalCode,
        e?.cancelReason,
        e?.cancelledAt,
        e?.deliveryTimeSlot,
        e?.deliveryTimeActual,
        e?.total,
        e?.orderType,
        e?.paymentType,
        e?.status,
        e?.customerPhoneNumber,
        e?.productSelection,
        e?.totalAmount,
        e?.totalQty,
        e?.current,
        e?.currentrtl,
        e?.pickupDelivery,
        e?.orderstatus
      ]);

  @override
  bool isValidKey(Object? o) => o is OrdersRecord;
}
