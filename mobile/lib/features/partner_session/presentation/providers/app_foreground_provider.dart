import 'dart:async';

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
