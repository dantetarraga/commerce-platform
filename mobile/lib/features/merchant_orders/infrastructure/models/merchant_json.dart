import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/orders/orders_infrastructure.dart';

/// Mapeo JSON → entidades de `merchant/*`.
abstract final class MerchantJson {
  static MerchantStore store(Map<String, dynamic> json) => MerchantStore(
    id: json['id'] as String,
    name: json['name'] as String,
    logoUrl: json['logoUrl'] as String?,
    isAcceptingOrders: json['isAcceptingOrders'] as bool,
    isOpenNow: json['isOpenNow'] as bool? ?? true,
  );

  static MerchantProduct product(Map<String, dynamic> json) => MerchantProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    imageUrl: json['imageUrl'] as String?,
    price: OrderJson.moneyFromJson(json['price']),
    section: json['section'] as String?,
    isAvailable: json['isAvailable'] as bool,
  );

  static const Map<String, PaymentKind> _paymentKinds = {
    'CASH': PaymentKind.cash,
    'YAPE': PaymentKind.yape,
    'PLIN': PaymentKind.plin,
    'CARD': PaymentKind.card,
  };

  static List<Map<String, dynamic>> _rows(Object? json) => (json as List? ?? const []).cast<Map<String, dynamic>>();

  static MerchantSummary summary(Map<String, dynamic> json) => MerchantSummary(
    deliveredCount: json['deliveredCount'] as int,
    cancelledCount: json['cancelledCount'] as int,
    activeCount: json['activeCount'] as int,
    sales: OrderJson.moneyFromJson(json['sales']),
    averageTicket: json['averageTicket'] == null ? null : OrderJson.moneyFromJson(json['averageTicket']),
    averagePrepMinutes: json['averagePrepMinutes'] as int?,
    peakHour: json['peakHour'] as int?,
    salesByHour: [
      for (final h in _rows(json['salesByHour']))
        HourSales(hour: h['hour'] as int, sales: OrderJson.moneyFromJson(h['sales']), orders: h['orders'] as int),
    ],
    payments: [
      for (final p in _rows(json['payments']))
        if (_paymentKinds[p['method']] case final kind?)
          PaymentSales(
            kind: kind,
            sales: OrderJson.moneyFromJson(p['sales']),
            orders: p['orders'] as int,
            share: p['share'] as int,
          ),
    ],
    topProducts: [
      for (final p in _rows(json['topProducts']))
        ProductSales(name: p['name'] as String, quantity: p['quantity'] as int, sales: OrderJson.moneyFromJson(p['sales'])),
    ],
  );
}
