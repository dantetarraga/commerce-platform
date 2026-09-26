import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/orders/orders.dart';

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

  static MerchantSummary summary(Map<String, dynamic> json) => MerchantSummary(
    deliveredCount: json['deliveredCount'] as int,
    cancelledCount: json['cancelledCount'] as int,
    activeCount: json['activeCount'] as int,
    sales: OrderJson.moneyFromJson(json['sales']),
  );
}
