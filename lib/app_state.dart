import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:csv/csv.dart';
import 'package:synchronized/synchronized.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    secureStorage = FlutterSecureStorage();
    await _safeInitAsync(() async {
      _status = (await secureStorage.getStringList('ff_status'))
              ?.map((x) => deserializeEnum<OrderStatus>(x)!)
              .toList() ??
          _status;
    });
    await _safeInitAsync(() async {
      _bluetoothPrinterAddress =
          await secureStorage.getString('ff_bluetooth_printer_address') ?? '';
    });
    await _safeInitAsync(() async {
      _bluetoothPrinterName =
          await secureStorage.getString('ff_bluetooth_printer_name') ?? '';
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late FlutterSecureStorage secureStorage;

  List<OrderStatus> _status = [];
  List<OrderStatus> get status => _status;
  set status(List<OrderStatus> value) {
    _status = value;
    secureStorage.setStringList(
        'ff_status', value.map((x) => x.serialize()).toList());
  }

  void deleteStatus() {
    secureStorage.delete(key: 'ff_status');
  }

  void addToStatus(OrderStatus value) {
    status.add(value);
    secureStorage.setStringList(
        'ff_status', _status.map((x) => x.serialize()).toList());
  }

  void removeFromStatus(OrderStatus value) {
    status.remove(value);
    secureStorage.setStringList(
        'ff_status', _status.map((x) => x.serialize()).toList());
  }

  void removeAtIndexFromStatus(int index) {
    status.removeAt(index);
    secureStorage.setStringList(
        'ff_status', _status.map((x) => x.serialize()).toList());
  }

  void updateStatusAtIndex(
    int index,
    OrderStatus Function(OrderStatus) updateFn,
  ) {
    status[index] = updateFn(_status[index]);
    secureStorage.setStringList(
        'ff_status', _status.map((x) => x.serialize()).toList());
  }

  void insertAtIndexInStatus(int index, OrderStatus value) {
    status.insert(index, value);
    secureStorage.setStringList(
        'ff_status', _status.map((x) => x.serialize()).toList());
  }

  bool _showsearch = true;
  bool get showsearch => _showsearch;
  set showsearch(bool value) {
    _showsearch = value;
  }

  List<DocumentReference> _orderRef = [];
  List<DocumentReference> get orderRef => _orderRef;
  set orderRef(List<DocumentReference> value) {
    _orderRef = value;
  }

  void addToOrderRef(DocumentReference value) {
    orderRef.add(value);
  }

  void removeFromOrderRef(DocumentReference value) {
    orderRef.remove(value);
  }

  void removeAtIndexFromOrderRef(int index) {
    orderRef.removeAt(index);
  }

  void updateOrderRefAtIndex(
    int index,
    DocumentReference Function(DocumentReference) updateFn,
  ) {
    orderRef[index] = updateFn(_orderRef[index]);
  }

  void insertAtIndexInOrderRef(int index, DocumentReference value) {
    orderRef.insert(index, value);
  }

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;
  set selectedDate(DateTime? value) {
    _selectedDate = value;
  }

  String _bluetoothPrinterAddress = '';
  String get bluetoothPrinterAddress => _bluetoothPrinterAddress;
  set bluetoothPrinterAddress(String value) {
    _bluetoothPrinterAddress = value;
    secureStorage.setString('ff_bluetooth_printer_address', value);
  }

  String _bluetoothPrinterName = '';
  String get bluetoothPrinterName => _bluetoothPrinterName;
  set bluetoothPrinterName(String value) {
    _bluetoothPrinterName = value;
    secureStorage.setString('ff_bluetooth_printer_name', value);
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}

extension FlutterSecureStorageExtensions on FlutterSecureStorage {
  static final _lock = Lock();

  Future<void> writeSync({required String key, String? value}) async =>
      await _lock.synchronized(() async {
        await write(key: key, value: value);
      });

  void remove(String key) => delete(key: key);

  Future<String?> getString(String key) async => await read(key: key);
  Future<void> setString(String key, String value) async =>
      await writeSync(key: key, value: value);

  Future<bool?> getBool(String key) async => (await read(key: key)) == 'true';
  Future<void> setBool(String key, bool value) async =>
      await writeSync(key: key, value: value.toString());

  Future<int?> getInt(String key) async =>
      int.tryParse(await read(key: key) ?? '');
  Future<void> setInt(String key, int value) async =>
      await writeSync(key: key, value: value.toString());

  Future<double?> getDouble(String key) async =>
      double.tryParse(await read(key: key) ?? '');
  Future<void> setDouble(String key, double value) async =>
      await writeSync(key: key, value: value.toString());

  Future<List<String>?> getStringList(String key) async =>
      await read(key: key).then((result) {
        if (result == null || result.isEmpty) {
          return null;
        }
        return CsvToListConverter()
            .convert(result)
            .first
            .map((e) => e.toString())
            .toList();
      });
  Future<void> setStringList(String key, List<String> value) async =>
      await writeSync(key: key, value: ListToCsvConverter().convert([value]));
}
