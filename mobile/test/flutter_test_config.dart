import 'dart:async';

import 'package:chaski/shared/design_system/components/app_avatar.dart';

/// Configuración global de tests (Flutter la carga antes de cada archivo).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Los tests no tienen red: el avatar va directo a las iniciales.
  AppAvatar.diceBearEnabled = false;
  await testMain();
}
