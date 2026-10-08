import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/errors/failure_mapper.dart';
import 'package:apamuy/core/network/dto/money_dto.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/storage/local_json_store.dart';
import 'package:apamuy/features/cart/domain/entities/cart.dart';
import 'package:apamuy/features/cart/domain/repositories/cart_repository.dart';
import 'package:apamuy/features/cart/infrastructure/datasources/coupon_remote_data_source.dart';
import 'package:apamuy/features/cart/infrastructure/models/cart_json.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._store, this._coupons);

  static const _key = 'apamuy.cart';

  final LocalJsonStore _store;
  final CouponRemoteDataSource _coupons;

  @override
  Future<Cart> load() async => CartJson.decode(await _store.read(_key));

  @override
  Future<void> save(Cart cart) => cart.isEmpty ? _store.remove(_key) : _store.write(_key, CartJson.encode(cart));

  @override
  Future<Result<Coupon>> validateCoupon({required String code, required String storeId, required Money subtotal}) =>
      guard(() async {
        final json = await _coupons.validate(code: code, storeId: storeId, subtotalCents: subtotal.cents);
        return Coupon(
          code: json['code'] as String,
          discount: MoneyDto.fromJson(json['discount'] as Map<String, dynamic>).toDomain(),
          label: json['label'] as String,
        );
      });
}
