import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/cart/domain/entities/cart.dart';

/// La bolsa vive en el dispositivo (sobrevive a cerrar la app y a la falta de
/// red); los cupones se validan en el backend.
abstract interface class CartRepository {
  Future<Cart> load();

  Future<void> save(Cart cart);

  Future<Result<Coupon>> validateCoupon({required String code, required String storeId, required Money subtotal});
}
