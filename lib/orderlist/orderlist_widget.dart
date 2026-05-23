import '/backend/backend.dart';
import '/orderlist1/orderlist1_widget.dart';

/// Canonical order list page lives in [Orderlist1Widget] at `/orderlist`.
class OrderlistWidget extends Orderlist1Widget {
  const OrderlistWidget({
    super.key,
    this.order,
  });

  /// Unused legacy parameter from the old orderlist page.
  final List<OrdersRecord>? order;

  static String get routeName => Orderlist1Widget.routeName;
  static String get routePath => Orderlist1Widget.routePath;
}
