import 'package:apamuy/core/errors/app_exception.dart';
import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/core/network/api_client.dart';

/// `POST /coupons/validate` → `{code, discount: {amount, currency}, label}`.
abstract interface class CouponRemoteDataSource {
  Future<Map<String, dynamic>> validate({required String code, required String storeId, required int subtotalCents});
}

class ApiCouponRemoteDataSource implements CouponRemoteDataSource {
  const ApiCouponRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<Map<String, dynamic>> validate({required String code, required String storeId, required int subtotalCents}) async {
    final data = await _api.post(
      '/coupons/validate',
      body: {'code': code, 'storeId': storeId, 'subtotal': {'amount': subtotalCents, 'currency': 'PEN'}},
    );
    return data as Map<String, dynamic>;
  }
}

/// Cupones de prueba: `BIENVENIDA` (S/ 5 desde S/ 15) y `ESPINAR` (S/ 3).
class FakeCouponRemoteDataSource implements CouponRemoteDataSource {
  const FakeCouponRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<Map<String, dynamic>> validate({required String code, required String storeId, required int subtotalCents}) async {
    await _backend.delay();
    switch (code.trim().toUpperCase()) {
      case 'BIENVENIDA':
        if (subtotalCents < 1500) {
          throw const ApiException(
            statusCode: 422,
            code: 'COUPON_MIN_NOT_REACHED',
            message: 'BIENVENIDA aplica desde S/ 15.00 en productos.',
          );
        }
        return {'code': 'BIENVENIDA', 'discount': _backend.money(500), 'label': 'S/ 5 de bienvenida'};
      case 'ESPINAR':
        return {'code': 'ESPINAR', 'discount': _backend.money(300), 'label': 'S/ 3 por pedir local'};
      default:
        throw const ApiException(
          statusCode: 422,
          code: 'COUPON_INVALID',
          message: 'Ese cupón no existe o ya venció.',
        );
    }
  }
}
