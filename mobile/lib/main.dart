import 'package:apamuy/apps/customer/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      // Riverpod 3 reintenta por defecto los providers que fallan; preferimos
      // mostrar el error y dejar que el usuario reintente.
      retry: (_, _) => null,
      child: const ApamuyApp(),
    ),
  );
}
