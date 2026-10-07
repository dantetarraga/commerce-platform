import 'package:chaski/core/utils/random_id.dart';

/// Clave de idempotencia: la misma request reusa la clave (doble tap, reintento
/// tras un corte de red) y una distinta recibe otra. [reset] al terminar con éxito.
final class IdempotencyKeys<T extends Object> {
  IdempotencyKeys({String Function()? generate})
    : _generate = generate ?? randomHexId;

  final String Function() _generate;
  T? _request;
  String? _key;

  String keyFor(T request) {
    if (_key == null || request != _request) {
      _request = request;
      _key = _generate();
    }
    return _key!;
  }

  void reset() {
    _request = null;
    _key = null;
  }
}
