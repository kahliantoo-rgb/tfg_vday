import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/driver_delivery_action_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';

void main() {
  test('driverCanStartOutForDelivery only for ready_to_delivery', () {
    expect(driverCanStartOutForDelivery(OrderStatus.ready_to_delivery), isTrue);
    expect(driverCanStartOutForDelivery(OrderStatus.processing), isFalse);
    expect(driverCanStartOutForDelivery(OrderStatus.out_of_delivery), isFalse);
    expect(driverCanStartOutForDelivery(OrderStatus.completed), isFalse);
  });

  test('driverCanRecordDelivery only for out_of_delivery', () {
    expect(driverCanRecordDelivery(OrderStatus.out_of_delivery), isTrue);
    expect(driverCanRecordDelivery(OrderStatus.ready_to_delivery), isFalse);
    expect(driverCanRecordDelivery(OrderStatus.processing), isFalse);
  });

  test('driverOrderVisibleOnAllTab excludes cancelled only', () {
    expect(driverOrderVisibleOnAllTab(OrderStatus.pending), isTrue);
    expect(driverOrderVisibleOnAllTab(OrderStatus.processing), isTrue);
    expect(driverOrderVisibleOnAllTab(OrderStatus.ready_to_delivery), isTrue);
    expect(driverOrderVisibleOnAllTab(OrderStatus.out_of_delivery), isTrue);
    expect(driverOrderVisibleOnAllTab(OrderStatus.completed), isTrue);
    expect(driverOrderVisibleOnAllTab(OrderStatus.cancelled), isFalse);
  });

  test('driverShowsWaitingForReadyHint for pending and processing only', () {
    expect(driverShowsWaitingForReadyHint(OrderStatus.pending), isTrue);
    expect(driverShowsWaitingForReadyHint(OrderStatus.processing), isTrue);
    expect(driverShowsWaitingForReadyHint(OrderStatus.ready_to_delivery), isFalse);
    expect(driverShowsWaitingForReadyHint(OrderStatus.out_of_delivery), isFalse);
    expect(driverShowsWaitingForReadyHint(OrderStatus.completed), isFalse);
  });
}
