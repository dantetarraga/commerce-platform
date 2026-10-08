import 'dart:async';

import 'package:apamuy/features/auth/auth.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_foreground_provider.g.dart';

/// `true` mientras la app está a la vista; en segundo plano no tiene sentido
/// consultar al backend cada pocos segundos.
@Riverpod(keepAlive: true)
class AppForeground extends _$AppForeground {
  @override
  bool build() {
    final listener = AppLifecycleListener(onStateChange: (s) => state = _isForeground(s));
    ref.onDispose(listener.dispose);
    return _isForeground(WidgetsBinding.instance.lifecycleState);
  }

  static bool _isForeground(AppLifecycleState? s) =>
      s == null || s == AppLifecycleState.resumed || s == AppLifecycleState.inactive;
}

/// Vuelve a pedir el provider de [ref] cada [every] mientras la app está a la
/// vista, y apenas vuelve del segundo plano.
void pollWhileForeground(Ref ref, Duration every) {
  final timer = Timer(every, () {
    if (ref.read(appForegroundProvider)) ref.invalidateSelf();
  });
  ref
    ..onDispose(timer.cancel)
    ..listen(appForegroundProvider, (was, now) {
      if (now && was == false) ref.invalidateSelf();
    });
}

/// Refresca el provider de [ref] apenas llega por WebSocket alguno de
/// [events]. La consulta queda de respaldo: cada [connectedEvery] con conexión
/// y cada [every] sin ella. Con [foregroundOnly] (lo normal) se pausa en segundo
/// plano; el negocio lo desactiva para que la alarma suene con la pantalla
/// bloqueada.
void refreshLive(
  Ref ref, {
  required Set<String> events,
  required Duration every,
  Duration connectedEvery = const Duration(seconds: 30),
  bool foregroundOnly = true,
}) {
  final realtime = ref.watch(realtimeClientProvider);
  final subscription = realtime.events.where((event) => events.contains(event.name)).listen((_) {
    if (!foregroundOnly || ref.read(appForegroundProvider)) ref.invalidateSelf();
  });
  ref.onDispose(subscription.cancel);
  final pollEvery = realtime.isConnected ? connectedEvery : every;
  if (foregroundOnly) {
    pollWhileForeground(ref, pollEvery);
  } else {
    final timer = Timer(pollEvery, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
}
