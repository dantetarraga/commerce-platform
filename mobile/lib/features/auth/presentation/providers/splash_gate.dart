import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_gate.g.dart';

/// Se abre cuando la animación de arranque terminó de mostrarse. Los routers no
/// salen del splash antes, así la marca se ve completa y la salida no se corta.
@Riverpod(keepAlive: true)
class SplashGate extends _$SplashGate {
  @override
  bool build() => false;

  void open() => state = true;
}
