import 'package:apamuy/apps/customer/app.dart';
import 'package:apamuy/core/config/env.dart';
import 'package:apamuy/core/push/firebase_push_messaging.dart';
import 'package:apamuy/core/push/push_messaging.dart';
import 'package:apamuy/core/push/push_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // En el modo demo no hay backend que envíe push.
  final push = AppEnv.fromEnvironment().useFakeData
      ? const NoopPushMessaging()
      : await initPushMessaging(app: PushApp.customer);
  runApp(
    ProviderScope(
      // Riverpod 3 reintenta por defecto los providers que fallan; preferimos
      // mostrar el error y dejar que el usuario reintente.
      retry: (_, _) => null,
      overrides: [pushMessagingProvider.overrideWithValue(push)],
      child: const ApamuyApp(),
    ),
  );
}
