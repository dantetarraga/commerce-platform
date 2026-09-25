import 'package:chaski/core/utils/idempotency_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late IdempotencyKeys<String> keys;
  var generated = 0;

  setUp(() {
    generated = 0;
    keys = IdempotencyKeys<String>(generate: () => 'key-${++generated}');
  });

  test('la misma request reusa la clave (doble tap o reintento)', () {
    expect(keys.keyFor('pedido A'), 'key-1');
    expect(keys.keyFor('pedido A'), 'key-1');
  });

  test('una request distinta recibe clave nueva', () {
    keys.keyFor('pedido A');
    expect(keys.keyFor('pedido B'), 'key-2');
    expect(keys.keyFor('pedido A'), 'key-3');
  });

  test('después de reset, la misma request es un pedido nuevo', () {
    keys
      ..keyFor('pedido A')
      ..reset();
    expect(keys.keyFor('pedido A'), 'key-2');
  });

  test('la clave por defecto es aleatoria y la acepta la API', () {
    final key = IdempotencyKeys<String>().keyFor('x');
    expect(key, matches(RegExp(r'^[0-9a-f]{32}$')));
  });
}
