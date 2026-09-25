import 'dart:math';

final _random = Random.secure();

/// 32 caracteres hexadecimales aleatorios (128 bits): request ids, idempotency keys.
String randomHexId() => List<int>.generate(
  16,
  (_) => _random.nextInt(256),
).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
