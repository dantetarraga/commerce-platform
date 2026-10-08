import 'package:apamuy/app_partner/partner_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entrada de Apamuy Socios:
/// `flutter run --flavor partner -t lib/main_partner.dart --dart-define-from-file=env/dev.json`.
void main() {
  runApp(
    ProviderScope(
      // Igual que la app del cliente: sin reintentos automáticos.
      retry: (_, _) => null,
      child: const PartnerApp(),
    ),
  );
}
