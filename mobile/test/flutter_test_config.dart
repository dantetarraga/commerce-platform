import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // toastification guarda un administrador global atado a la capa donde pintó;
  // cada test monta una app nueva, así que se empieza de cero.
  setUp(toastification.managers.clear);
  await testMain();
}
