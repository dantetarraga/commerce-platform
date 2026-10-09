import 'package:apamuy/apps/partner/partner_app.dart';
import 'package:apamuy/core/config/env.dart';
import 'package:apamuy/core/push/firebase_push_messaging.dart';
import 'package:apamuy/core/push/push_messaging.dart';
import 'package:apamuy/core/push/push_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entrada de Apamuy Socios:
/// `flutter run --flavor partner -t lib/main_partner.dart --dart-define-from-file=env/dev.json`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final push = AppEnv.fromEnvironment().useFakeData
      ? const NoopPushMessaging()
      : await initPushMessaging(app: PushApp.partner);
  runApp(
    ProviderScope(
      // Igual que la app del cliente: sin reintentos automáticos.
      retry: (_, _) => null,
      overrides: [
        pushMessagingProvider.overrideWithValue(push),
        pushAppProvider.overrideWithValue(PushApp.partner),
      ],
      child: const PartnerApp(),
    ),
  );
}
