import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

/// Configuración común de todos los tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // toastification (detrás de AppToast) guarda un administrador global por
  // posición que recuerda la capa donde pintó. En la app esa capa es la raíz y
  // vive siempre; entre tests cada app es nueva, así que se empieza de cero.
  setUp(toastification.managers.clear);
  await testMain();
}
