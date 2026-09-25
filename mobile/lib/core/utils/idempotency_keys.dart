import 'package:chaski/core/utils/random_id.dart';

/// Clave de idempotencia para una operación que el usuario puede repetir
/// (confirmar un pedido): la misma request reusa la clave, así un doble tap o
/// un reintento tras un corte de red no la duplican; una request distinta
/// recibe una clave nueva. [reset] al terminar con éxito.
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
