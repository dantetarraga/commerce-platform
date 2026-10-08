import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/features/orders/domain/staff_order.dart';
import 'package:apamuy/features/orders/infrastructure/models/order_json.dart';

/// Contrato JSON del pedido para socios (`merchant/*` y `courier/*`): el
/// `OrderJson` más los campos de `docs/OPERACION.md` §7.
abstract final class StaffOrderJson {
  static const Map<String, CollectionMethod> _methods = {
    'CASH': CollectionMethod.cash,
    'YAPE': CollectionMethod.yape,
    'PLIN': CollectionMethod.plin,
  };

  static String methodToJson(CollectionMethod m) => _methods.entries.firstWhere((e) => e.value == m).key;

  static GeoCoordinates _location(Object? json) {
    final m = json! as Map<String, dynamic>;
    return GeoCoordinates.trusted((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble());
  }

  static StaffOrder fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>;
    final pickup = json['pickup'] as Map<String, dynamic>;
    final collection = json['collection'] as Map<String, dynamic>?;
    return StaffOrder(
      order: OrderJson.fromJson(json),
      customerName: customer['name'] as String,
      customerPhone: customer['phone'] as String,
      deliveryLocation: _location(json['deliveryLocation']),
      pickup: Pickup(
        address: pickup['address'] as String,
        phone: pickup['phone'] as String?,
        location: _location(pickup['location']),
      ),
      distanceMeters: json['distanceMeters'] as int? ?? 0,
      cancelReason: json['cancelReason'] as String?,
      collection: collection == null
          ? null
          : Collection(
              method: _methods[collection['method']] ?? CollectionMethod.cash,
              amount: OrderJson.moneyFromJson(collection['amount']),
              at: DateTime.parse(collection['collectedAt'] as String).toLocal(),
            ),
    );
  }
}
