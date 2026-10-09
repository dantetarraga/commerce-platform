import 'package:apamuy/core/push/push_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_providers.g.dart';

/// El `main` de cada app lo reemplaza con Firebase; en tests y modo demo no hace nada.
@Riverpod(keepAlive: true)
PushMessaging pushMessaging(Ref ref) => const NoopPushMessaging();

/// Qué app corre: el `main` de Socios lo reemplaza con [PushApp.partner].
@Riverpod(keepAlive: true)
PushApp pushApp(Ref ref) => PushApp.customer;
