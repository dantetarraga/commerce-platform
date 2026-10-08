import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/features/orders/domain/order.dart';

/// Contrato JSON de `/orders` (igual en la API real y en el backend fake).
abstract final class OrderJson {
  static const Map<String, OrderStatus> _status = {
    'RECEIVED': OrderStatus.received,
    'CONFIRMED': OrderStatus.confirmed,
    'PREPARING': OrderStatus.preparing,
    'READY': OrderStatus.ready,
    'COURIER_ASSIGNED': OrderStatus.courierAssigned,
    'ON_THE_WAY': OrderStatus.onTheWay,
    'DELIVERED': OrderStatus.delivered,
    'CANCELLED': OrderStatus.cancelled,
  };

  static String statusToJson(OrderStatus s) => _status.entries.firstWhere((e) => e.value == s).key;

  static OrderStatus statusFromJson(String s) => _status[s] ?? OrderStatus.received;

  static Money moneyFromJson(Object? json) => _money(json);

  static Money _money(Object? json) {
    final m = json! as Map<String, dynamic>;
    return Money(m['amount'] as int, currency: m['currency'] as String? ?? Money.defaultCurrency);
  }

  static Map<String, Object?> money(Money m) => {'amount': m.cents, 'currency': m.currency};

  static PaymentMethod paymentFromJson(Map<String, dynamic> json) => switch (json['type']) {
    'YAPE' => const YapePayment(),
    'PLIN' => const PlinPayment(),
    'CARD' => const CardPayment(),
    _ => CashPayment(changeFor: json['changeFor'] == null ? null : _money(json['changeFor'])),
  };

  static Map<String, Object?> paymentToJson(PaymentMethod p) => switch (p) {
    YapePayment() => {'type': 'YAPE'},
    PlinPayment() => {'type': 'PLIN'},
    CardPayment() => {'type': 'CARD'},
    CashPayment(:final changeFor) => {'type': 'CASH', 'changeFor': changeFor == null ? null : money(changeFor)},
  };

  /// `{ lat, lng }` → coordenadas; `null` si falta o está fuera de rango.
  static GeoCoordinates? locationFromJson(Object? json) {
    if (json is! Map) return null;
    final lat = json['lat'];
    final lng = json['lng'];
    if (lat is! num || lng is! num) return null;
    return GeoCoordinates.create(lat.toDouble(), lng.toDouble()).valueOrNull;
  }

  static CourierPosition? positionFromJson(Object? json) {
    final coordinates = locationFromJson(json);
    final at = json is Map ? json['at'] : null;
    if (coordinates == null || at is! String) return null;
    return CourierPosition(coordinates, DateTime.parse(at).toLocal());
  }

  static Order fromJson(Map<String, dynamic> json) {
    final store = json['store'] as Map<String, dynamic>;
    final address = json['address'] as Map<String, dynamic>;
    final courier = json['courier'] as Map<String, dynamic>?;
    DateTime? date(String key) => json[key] == null ? null : DateTime.parse(json[key] as String).toLocal();
    return Order(
      id: json['id'] as String,
      code: json['code'] as String,
      store: OrderStore(
        id: store['id'] as String,
        name: store['name'] as String,
        logoUrl: store['logoUrl'] as String?,
        ownerName: store['ownerName'] as String?,
        location: locationFromJson(store['location']),
      ),
      lines: [
        for (final l in (json['lines'] as List).cast<Map<String, dynamic>>())
          OrderLine(
            productId: l['productId'] as String?,
            name: l['name'] as String,
            quantity: l['quantity'] as int,
            total: _money(l['total']),
            description: l['description'] as String? ?? '',
            notes: l['notes'] as String? ?? '',
          ),
      ],
      subtotal: _money(json['subtotal']),
      deliveryFee: _money(json['deliveryFee']),
      discount: _money(json['discount']),
      tip: json['tip'] == null ? const Money.zero() : _money(json['tip']),
      total: _money(json['total']),
      addressTitle: address['title'] as String,
      addressStreet: address['street'] as String,
      addressReference: address['reference'] as String? ?? '',
      destination: locationFromJson(address['location']),
      payment: paymentFromJson(json['payment'] as Map<String, dynamic>),
      status: statusFromJson(json['status'] as String),
      events: [
        for (final e in (json['events'] as List).cast<Map<String, dynamic>>())
          OrderEvent(statusFromJson(e['status'] as String), DateTime.parse(e['at'] as String).toLocal()),
      ],
      placedAt: date('placedAt')!,
      courier: courier == null
          ? null
          : Courier(
              name: courier['name'] as String,
              vehicle: courier['vehicle'] as String,
              since: courier['since'] as int?,
              avatarUrl: courier['avatarUrl'] as String?,
              position: positionFromJson(courier['location']),
            ),
      estimatedArrival: date('estimatedArrival'),
      scheduledFor: date('scheduledFor'),
      rating: json['rating'] as int?,
      notes: json['notes'] as String? ?? '',
    );
  }

  static Map<String, Object?> requestToJson(PlaceOrderRequest r) => {
    'storeId': r.storeId,
    'items': [
      for (final i in r.items)
        {
          'productId': i.productId,
          'variantId': i.variantId,
          'optionValueIds': i.optionValueIds,
          'quantity': i.quantity,
          'notes': i.notes,
        },
    ],
    'address': {
      'title': r.addressTitle,
      'street': r.addressStreet,
      'reference': r.addressReference,
      'latitude': r.latitude,
      'longitude': r.longitude,
    },
    'payment': paymentToJson(r.payment),
    'couponCode': r.couponCode,
    'scheduledFor': r.scheduledFor?.toUtc().toIso8601String(),
    'tip': money(r.tip),
    'notes': r.notes,
  };
}
