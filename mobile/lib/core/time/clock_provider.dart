import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// Cada cuánto avanza [clockProvider].
const clockTick = Duration(seconds: 30);

/// La hora actual, que avanza cada [clockTick]. Para contadores que deben
/// moverse solos ("faltan 8 min", "en fogón desde…") sin depender del polling
/// ni de un `Timer` por widget: `ref.watch(clockProvider).value ?? DateTime.now()`.
/// Se apaga cuando nadie lo mira.
@riverpod
Stream<DateTime> clock(Ref ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(clockTick, (_) => DateTime.now());
}
