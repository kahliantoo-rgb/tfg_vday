import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class InvoicesRecord extends FirestoreRecord {
  InvoicesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _invoiceNumber;
  String get invoiceNumber => _invoiceNumber ?? '';
  bool hasInvoiceNumber() => _invoiceNumber != null;

  DocumentReference? _customerRef;
  DocumentReference? get customerRef => _customerRef;
  bool hasCustomerRef() => _customerRef != null;

  String? _customerName;
  String get customerName => _customerName ?? '';
  bool hasCustomerName() => _customerName != null;

  String? _creditTerm;
  String get creditTerm => _creditTerm ?? '';
  bool hasCreditTerm() => _creditTerm != null;

  List<DocumentReference>? _orderRefs;
  List<DocumentReference> get orderRefs => _orderRefs ?? const [];
  bool hasOrderRefs() => _orderRefs != null;

  List<String>? _orderIds;
  List<String> get orderIds => _orderIds ?? const [];
  bool hasOrderIds() => _orderIds != null;

  double? _subtotal;
  double get subtotal => _subtotal ?? 0.0;
  bool hasSubtotal() => _subtotal != null;

  double? _discount;
  double get discount => _discount ?? 0.0;
  bool hasDiscount() => _discount != null;

  String? _discountLabel;
  String get discountLabel => _discountLabel ?? '';
  bool hasDiscountLabel() => _discountLabel != null;

  double? _total;
  double get total => _total ?? 0.0;
  bool hasTotal() => _total != null;

  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  DateTime? _paidAt;
  DateTime? get paidAt => _paidAt;
  bool hasPaidAt() => _paidAt != null;

  String? _paymentProofUrl;
  String get paymentProofUrl => _paymentProofUrl ?? '';
  bool hasPaymentProofUrl() => _paymentProofUrl != null;

  DateTime? _paymentProofAt;
  DateTime? get paymentProofAt => _paymentProofAt;
  bool hasPaymentProofAt() => _paymentProofAt != null;

  DocumentReference? _companyRef;
  DocumentReference? get companyRef => _companyRef;
  bool hasCompanyRef() => _companyRef != null;

  void _initializeFields() {
    _invoiceNumber = snapshotData['invoice_number'] as String?;
    _customerRef = snapshotData['customer_ref'] as DocumentReference?;
    _customerName = snapshotData['customer_name'] as String?;
    _creditTerm = snapshotData['credit_term'] as String?;
    _orderRefs = getDataList(snapshotData['order_refs']);
    _orderIds = getDataList(snapshotData['order_ids']);
    _subtotal = castToType<double>(snapshotData['subtotal']);
    _discount = castToType<double>(snapshotData['discount']);
    _discountLabel = snapshotData['discount_label'] as String?;
    _total = castToType<double>(snapshotData['total']);
    _status = snapshotData['status'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _paidAt = snapshotData['paid_at'] as DateTime?;
    _paymentProofUrl = snapshotData['payment_proof_url'] as String?;
    _paymentProofAt = snapshotData['payment_proof_at'] as DateTime?;
    _companyRef = snapshotData['companyRef'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('invoices');

  static Stream<InvoicesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => InvoicesRecord.fromSnapshot(s));

  static Future<InvoicesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => InvoicesRecord.fromSnapshot(s));

  static InvoicesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      InvoicesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static InvoicesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      InvoicesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'InvoicesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is InvoicesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createInvoicesRecordData({
  String? invoiceNumber,
  DocumentReference? customerRef,
  String? customerName,
  String? creditTerm,
  List<DocumentReference>? orderRefs,
  List<String>? orderIds,
  double? subtotal,
  double? discount,
  String? discountLabel,
  double? total,
  String? status,
  DateTime? createdTime,
  DateTime? paidAt,
  String? paymentProofUrl,
  DateTime? paymentProofAt,
  DocumentReference? companyRef,
}) {
  return mapToFirestore(
    <String, dynamic>{
      'invoice_number': invoiceNumber,
      'customer_ref': customerRef,
      'customer_name': customerName,
      'credit_term': creditTerm,
      'order_refs': orderRefs,
      'order_ids': orderIds,
      'subtotal': subtotal,
      'discount': discount,
      'discount_label': discountLabel,
      'total': total,
      'status': status,
      'created_time': createdTime,
      'paid_at': paidAt,
      'payment_proof_url': paymentProofUrl,
      'payment_proof_at': paymentProofAt,
      'companyRef': companyRef,
    }.withoutNulls,
  );
}

class InvoicesRecordDocumentEquality implements Equality<InvoicesRecord> {
  const InvoicesRecordDocumentEquality();

  @override
  bool equals(InvoicesRecord? e1, InvoicesRecord? e2) =>
      e1?.reference == e2?.reference;

  @override
  int hash(InvoicesRecord? e) => e?.reference.hashCode ?? 0;

  @override
  bool isValidKey(Object? o) => o is InvoicesRecord;
}
