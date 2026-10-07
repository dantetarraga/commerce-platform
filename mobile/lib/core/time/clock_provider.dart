import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// Cada cuánto avanza [clockProvider].
const clockTick = Duration(seconds: 30);

/// La hora actual, que avanza cada [clockTick]: para contadores que se mueven
/// solos sin polling ni un `Timer` por widget. Se apaga cuando nadie lo mira.
@riverpod
Stream<DateTime> clock(Ref ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(clockTick, (_) => DateTime.now());
}
