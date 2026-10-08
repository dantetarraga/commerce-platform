import 'package:apamuy/core/storage/local_json_store.dart';
import 'package:apamuy/features/checkout/domain/checkout.dart';

/// Recuerda el último método de pago para precargarlo (menos toques).
class CheckoutPreferences {
  const CheckoutPreferences(this._store);

  static const _key = 'apamuy.checkout';

  final LocalJsonStore _store;

  Future<PaymentKind?> lastPayment() async {
    final json = await _store.read(_key);
    if (json is! Map) return null;
    return PaymentKind.offered.where((k) => k.name == json['payment']).firstOrNull;
  }

  Future<void> rememberPayment(PaymentKind kind) => _store.write(_key, {'payment': kind.name});
}
