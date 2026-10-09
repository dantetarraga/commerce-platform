import 'dart:async';

import 'package:apamuy/core/push/local_alerts.dart';
import 'package:apamuy/core/push/push_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Push solo de datos con la app cerrada o en segundo plano. Corre en otro isolate:
/// solo la alarma del negocio necesita esto (el resto de avisos los muestra el sistema).
@pragma('vm:entry-point')
Future<void> partnerBackgroundPush(RemoteMessage message) async {
  if (message.data['type'] != 'NEW_ORDER') return;
  await Firebase.initializeApp();
  await LocalAlerts.init();
  await LocalAlerts.showAlarm(message.data.map((key, value) => MapEntry(key, '$value')));
}

/// Push con Firebase. Si la app no tiene `google-services.json` (o falla Firebase), queda
/// [NoopPushMessaging]: la app funciona igual, solo que sin push.
Future<PushMessaging> initPushMessaging({required PushApp app}) async {
  try {
    await Firebase.initializeApp();
  } on Object catch (error) {
    debugPrint('Push desactivado: $error');
    return const NoopPushMessaging();
  }
  final opened = StreamController<Map<String, String>>.broadcast();
  await LocalAlerts.init(onTap: opened.add);
  if (app == PushApp.partner) FirebaseMessaging.onBackgroundMessage(partnerBackgroundPush);

  final messaging = FirebaseMessaging.instance;
  // Android 13+ e iOS piden permiso; sin él no hay token y el backend no envía nada.
  await messaging.requestPermission();
  FirebaseMessaging.onMessageOpenedApp.listen((message) => opened.add(_data(message)));

  return _FirebasePushMessaging(messaging, opened, () async {
    final fromPush = await messaging.getInitialMessage();
    if (fromPush != null) return _data(fromPush);
    return LocalAlerts.launchData();
  });
}

Map<String, String> _data(RemoteMessage message) => message.data.map((key, value) => MapEntry(key, '$value'));

class _FirebasePushMessaging implements PushMessaging {
  _FirebasePushMessaging(this._messaging, this._opened, Future<Map<String, String>?> Function() launch)
    : _launch = launch();

  final FirebaseMessaging _messaging;
  final StreamController<Map<String, String>> _opened;

  /// El aviso que abrió la app: se entrega una sola vez, al primer suscriptor.
  final Future<Map<String, String>?> _launch;
  var _launchDelivered = false;

  @override
  Future<String?> token() async {
    try {
      return await _messaging.getToken();
    } on Object catch (error) {
      debugPrint('Sin token de push: $error');
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<Map<String, String>> get onOpened async* {
    if (!_launchDelivered) {
      _launchDelivered = true;
      final launch = await _launch;
      if (launch != null && launch.isNotEmpty) yield launch;
    }
    yield* _opened.stream;
  }
}
