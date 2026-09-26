import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'order_alarm.g.dart';

/// Alarma de pedidos de Chaski Socios mientras la app está abierta: suena en
/// bucle hasta que alguien atiende y mantiene la pantalla encendida en los
/// modos de trabajo. Con la app cerrada avisa el push (fase 4).
abstract interface class OrderAlarm {
  Future<void> ring();

  Future<void> silence();

  /// Pantalla siempre encendida mientras se trabaja (negocio abierto,
  /// repartidor conectado).
  Future<void> keepAwake({required bool on});
}

class DeviceOrderAlarm implements OrderAlarm {
  DeviceOrderAlarm() : _player = AudioPlayer();

  static const _asset = 'sounds/new_order.wav';

  final AudioPlayer _player;
  var _ringing = false;

  @override
  Future<void> ring() async {
    if (_ringing) return;
    _ringing = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(_asset));
    } on Object catch (e) {
      _ringing = false;
      debugPrint('No se pudo sonar la alarma: $e');
    }
  }

  @override
  Future<void> silence() async {
    if (!_ringing) return;
    _ringing = false;
    try {
      await _player.stop();
    } on Object catch (e) {
      debugPrint('No se pudo detener la alarma: $e');
    }
  }

  @override
  Future<void> keepAwake({required bool on}) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } on Object catch (e) {
      debugPrint('No se pudo cambiar el bloqueo de pantalla: $e');
    }
  }

  Future<void> dispose() => _player.dispose();
}

@Riverpod(keepAlive: true)
OrderAlarm orderAlarm(Ref ref) {
  final alarm = DeviceOrderAlarm();
  ref.onDispose(alarm.dispose);
  return alarm;
}
