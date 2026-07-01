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

  // "recipient_name" field.
  String? _recipientName;
  String get recipientName => _recipientName ?? '';
  bool hasRecipientName() => _recipientName != null;

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

  double? _cashReceived;
  double get cashReceived => _cashReceived ?? 0.0;
  bool hasCashReceived() => _cashReceived != null;

  double? _cashChange;
  double get cashChange => _cashChange ?? 0.0;
  bool hasCashChange() => _cashChange != null;

  double? _amountPaid;
  double get amountPaid => _amountPaid ?? 0.0;
  bool hasAmountPaid() => _amountPaid != null;

  double? _balanceDue;
  double get balanceDue => _balanceDue ?? 0.0;
  bool hasBalanceDue() => _balanceDue != null;

  // "status" field.
  OrderStatus? _status;
  OrderStatus? get status => _status;
  bool hasStatus() => _status != null;

  // "customer_phone_number" field — billing customer contact (from customer profile).
  String? _customerPhoneNumber;
  String get customerPhoneNumber => _customerPhoneNumber ?? '';
  bool hasCustomerPhoneNumber() => _customerPhoneNumber != null;

  // "recipient_phone_number" field — delivery recipient contact.
  String? _recipientPhoneNumber;
  String get recipientPhoneNumber => _recipientPhoneNumber ?? '';
  bool hasRecipientPhoneNumber() => _recipientPhoneNumber != null;

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

  // "companyRef" field — tenant (Companies document).
  DocumentReference? _companyRef;
  DocumentReference? get companyRef => _companyRef;
  bool hasCompanyRef() => _companyRef != null;

  DocumentReference? _customerRef;
  DocumentReference? get customerRef => _customerRef;
  bool hasCustomerRef() => _customerRef != null;

  DocumentReference? _invoiceRef;
  DocumentReference? get invoiceRef => _invoiceRef;
  bool hasInvoiceRef() => _invoiceRef != null;

  String? _invoiceNumber;
  String get invoiceNumber => _invoiceNumber ?? '';
  bool hasInvoiceNumber() => _invoiceNumber != null;

  String? _invoicePaymentStatus;
  String get invoicePaymentStatus => _invoicePaymentStatus ?? '';
  bool hasInvoicePaymentStatus() => _invoicePaymentStatus != null;

  String? _source;
  String get source => _source ?? '';
  bool hasSource() => _source != null;

  String? _externalOrderId;
  String get externalOrderId => _externalOrderId ?? '';
  bool hasExternalOrderId() => _externalOrderId != null;

  String? _externalOrderName;
  String get externalOrderName => _externalOrderName ?? '';
  bool hasExternalOrderName() => _externalOrderName != null;

  // "delivery_proof_url" field.
  String? _deliveryProofUrl;
  String get deliveryProofUrl => _deliveryProofUrl ?? '';
  bool hasDeliveryProofUrl() => _deliveryProofUrl != null;

  List<String>? _deliveryProofUrls;
  List<String> get deliveryProofUrls => _deliveryProofUrls ?? const [];
  bool hasDeliveryProofUrls() => _deliveryProofUrls != null;

  // "delivery_proof_at" field.
  DateTime? _deliveryProofAt;
  DateTime? get deliveryProofAt => _deliveryProofAt;
  bool hasDeliveryProofAt() => _deliveryProofAt != null;

  // Locked material cost at first payment (profit report uses this, not live catalog).
  double? _materialUsageCost;
  double get materialUsageCost => _materialUsageCost ?? 0.0;
  bool hasMaterialUsageCost() => _materialUsageCost != null;

  Map<String, double>? _materialCostSnapshot;
  Map<String, double> get materialCostSnapshot => _materialCostSnapshot ?? const {};

  DateTime? _materialCostSnapshottedAt;
  DateTime? get materialCostSnapshottedAt => _materialCostSnapshottedAt;
  bool hasMaterialCostSnapshot() => _materialCostSnapshottedAt != null;

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final entry in raw)
        if (entry is String && entry.trim().isNotEmpty) entry.trim(),
    ];
  }

  void _initializeFields() {
    _clientName = snapshotData['client_name'] as String?;
    _recipientName = snapshotData['recipient_name'] as String?;
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
    _cashReceived = castToType<double>(snapshotData['cash_received']);
    _cashChange = castToType<double>(snapshotData['cash_change']);
    _amountPaid = castToType<double>(snapshotData['amount_paid']);
    _balanceDue = castToType<double>(snapshotData['balance_due']);
    _status = snapshotData['status'] is OrderStatus
        ? snapshotData['status']
        : deserializeEnum<OrderStatus>(snapshotData['status']);
    _customerPhoneNumber = snapshotData['customer_phone_number'] as String?;
    _recipientPhoneNumber = snapshotData['recipient_phone_number'] as String?;
    _productSelection = snapshotData['ProductSelection'] as DocumentReference?;
    _totalAmount = castToType<double>(snapshotData['totalAmount']);
    _totalQty = castToType<int>(snapshotData['totalQty']);
    _current = castToType<int>(snapshotData['current']);
    _currentrtl = castToType<int>(snapshotData['currentrtl']);
    _pickupDelivery = snapshotData['pickup_delivery'] as String?;
    _orderstatus = snapshotData['orderstatus'] as String?;
    _companyRef = snapshotData['companyRef'] as DocumentReference?;
    _customerRef = snapshotData['customerRef'] as DocumentReference?;
    _invoiceRef = snapshotData['invoice_ref'] as DocumentReference?;
    _invoiceNumber = snapshotData['invoice_number'] as String?;
    _invoicePaymentStatus =
        snapshotData['invoice_payment_status'] as String?;
    _source = snapshotData['source'] as String?;
    _externalOrderId = snapshotData['externalOrderId'] as String?;
    _externalOrderName = snapshotData['externalOrderName'] as String?;
    _deliveryProofUrl = snapshotData['delivery_proof_url'] as String?;
    _deliveryProofUrls = _parseStringList(snapshotData['delivery_proof_urls']);
    _deliveryProofAt = snapshotData['delivery_proof_at'] as DateTime?;
    _materialUsageCost = castToType<double>(snapshotData['material_usage_cost']);
    _materialCostSnapshottedAt =
        snapshotData['material_cost_snapshotted_at'] as DateTime?;
    final rawSnapshot = snapshotData['material_cost_snapshot'];
    if (rawSnapshot is Map) {
      _materialCostSnapshot = rawSnapshot.map(
        (key, value) => MapEntry(
          key.toString(),
          castToType<double>(value) ?? 0.0,
        ),
      );
    }
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('orders');

  static Stream<OrdersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => OrdersRecord.fromSnapshot(s));

  static Future<OrdersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => OrdersRecord.fromSnapshot(s));

  static OrdersRecord fromSnapshot(DocumentSnapshot snapshot) {
    final raw = snapshot.data();
    return OrdersRecord._(
      snapshot.reference,
      mapFromFirestore(
        raw != null ? raw as Map<String, dynamic> : <String, dynamic>{},
      ),
    );
  }

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
  String? recipientName,
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
  double? cashReceived,
  double? cashChange,
  double? amountPaid,
  double? balanceDue,
  OrderStatus? status,
  String? customerPhoneNumber,
  String? recipientPhoneNumber,
  DocumentReference? productSelection,
  double? totalAmount,
  int? totalQty,
  int? current,
  int? currentrtl,
  String? pickupDelivery,
  String? orderstatus,
  DocumentReference? companyRef,
  DocumentReference? customerRef,
  DocumentReference? invoiceRef,
  String? invoiceNumber,
  String? invoicePaymentStatus,
  String? source,
  String? externalOrderId,
  String? externalOrderName,
  String? deliveryProofUrl,
  List<String>? deliveryProofUrls,
  DateTime? deliveryProofAt,
  double? materialUsageCost,
  Map<String, double>? materialCostSnapshot,
  DateTime? materialCostSnapshottedAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'client_name': clientName,
      'recipient_name': recipientName,
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
      'cash_received': cashReceived,
      'cash_change': cashChange,
      'amount_paid': amountPaid,
      'balance_due': balanceDue,
      'status': status,
      'customer_phone_number': customerPhoneNumber,
      'recipient_phone_number': recipientPhoneNumber,
      'ProductSelection': productSelection,
      'totalAmount': totalAmount,
      'totalQty': totalQty,
      'current': current,
      'currentrtl': currentrtl,
      'pickup_delivery': pickupDelivery,
      'orderstatus': orderstatus,
      'companyRef': companyRef,
      'customerRef': customerRef,
      'invoice_ref': invoiceRef,
      'invoice_number': invoiceNumber,
      'invoice_payment_status': invoicePaymentStatus,
      'source': source,
      'externalOrderId': externalOrderId,
      'externalOrderName': externalOrderName,
      'delivery_proof_url': deliveryProofUrl,
      'delivery_proof_urls': deliveryProofUrls,
      'delivery_proof_at': deliveryProofAt,
      'material_usage_cost': materialUsageCost,
      'material_cost_snapshot': materialCostSnapshot,
      'material_cost_snapshotted_at': materialCostSnapshottedAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class OrdersRecordDocumentEquality implements Equality<OrdersRecord> {
  const OrdersRecordDocumentEquality();

  @override
  bool equals(OrdersRecord? e1, OrdersRecord? e2) {
    return e1?.clientName == e2?.clientName &&
        e1?.recipientName == e2?.recipientName &&
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
        e1?.cashReceived == e2?.cashReceived &&
        e1?.cashChange == e2?.cashChange &&
        e1?.amountPaid == e2?.amountPaid &&
        e1?.balanceDue == e2?.balanceDue &&
        e1?.status == e2?.status &&
        e1?.customerPhoneNumber == e2?.customerPhoneNumber &&
        e1?.recipientPhoneNumber == e2?.recipientPhoneNumber &&
        e1?.productSelection == e2?.productSelection &&
        e1?.totalAmount == e2?.totalAmount &&
        e1?.totalQty == e2?.totalQty &&
        e1?.current == e2?.current &&
        e1?.currentrtl == e2?.currentrtl &&
        e1?.pickupDelivery == e2?.pickupDelivery &&
        e1?.orderstatus == e2?.orderstatus &&
        e1?.companyRef == e2?.companyRef &&
        e1?.customerRef == e2?.customerRef &&
        e1?.invoiceRef == e2?.invoiceRef &&
        e1?.invoiceNumber == e2?.invoiceNumber &&
        e1?.invoicePaymentStatus == e2?.invoicePaymentStatus &&
        e1?.deliveryProofUrl == e2?.deliveryProofUrl &&
        e1?.deliveryProofAt == e2?.deliveryProofAt &&
        e1?.materialUsageCost == e2?.materialUsageCost &&
        e1?.materialCostSnapshottedAt == e2?.materialCostSnapshottedAt;
  }

  @override
  int hash(OrdersRecord? e) => const ListEquality().hash([
        e?.clientName,
        e?.recipientName,
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
        e?.cashReceived,
        e?.cashChange,
        e?.amountPaid,
        e?.balanceDue,
        e?.status,
        e?.customerPhoneNumber,
        e?.recipientPhoneNumber,
        e?.productSelection,
        e?.totalAmount,
        e?.totalQty,
        e?.current,
        e?.currentrtl,
        e?.pickupDelivery,
        e?.orderstatus,
        e?.companyRef,
        e?.customerRef,
        e?.invoiceRef,
        e?.invoiceNumber,
        e?.invoicePaymentStatus,
        e?.deliveryProofUrl,
        e?.deliveryProofAt,
        e?.materialUsageCost,
        e?.materialCostSnapshottedAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is OrdersRecord;
}
