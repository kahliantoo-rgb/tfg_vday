import 'package:collection/collection.dart';

enum UserRole {
  admin,
  senior_florist,
  driver,
}

enum OrderStatus {
  pending,
  processing,
  ready_to_delivery,
  out_of_delivery,
  completed,
  cancelled,
}

extension FFEnumExtensions<T extends Enum> on T {
  String serialize() => name;
}

extension FFEnumListExtensions<T extends Enum> on Iterable<T> {
  T? deserialize(String? value) =>
      firstWhereOrNull((e) => e.serialize() == value);
}

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (UserRole):
      return UserRole.values.deserialize(value) as T?;
    case (OrderStatus):
      return OrderStatus.values.deserialize(value) as T?;
    default:
      return null;
  }
}
