import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'order_alarm.g.dart';

/// Alarma de pedidos mientras la app está abierta: un tono que se repite hasta
/// que alguien atiende. Con la app cerrada avisa el push (fase 4).
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

  /// Pausa entre tonos: insiste sin volverse una sirena.
  static const _every = Duration(seconds: 5);

  final AudioPlayer _player;
  Timer? _repeat;

  @override
  Future<void> ring() async {
    if (_repeat != null) return;
    _repeat = Timer.periodic(_every, (_) => _play());
    await _play();
  }

  Future<void> _play() async {
    try {
      await _player.stop();
      await _player.play(AssetSource(_asset));
    } on Object catch (e) {
      debugPrint('No se pudo sonar la alarma: $e');
    }
  }

  @override
  Future<void> silence() async {
    if (_repeat == null) return;
    _repeat?.cancel();
    _repeat = null;
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

  Future<void> dispose() {
    _repeat?.cancel();
    return _player.dispose();
  }
}

@Riverpod(keepAlive: true)
OrderAlarm orderAlarm(Ref ref) {
  final alarm = DeviceOrderAlarm();
  ref.onDispose(alarm.dispose);
  return alarm;
}
