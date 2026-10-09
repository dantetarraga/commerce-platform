import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Canales de Android. Los ids coinciden con `channel` del backend (`PushChannel`).
abstract final class PushChannels {
  static const orders = AndroidNotificationChannel(
    'orders',
    'Pedidos',
    description: 'Cómo va tu pedido y avisos de la operación.',
    importance: Importance.high,
  );

  /// Pedido nuevo para el negocio: suena hasta que lo atiendan, aunque el celular esté en silencio.
  static const orderAlarm = AndroidNotificationChannel(
    'order_alarm',
    'Pedidos nuevos',
    description: 'Alarma cuando entra un pedido a tu negocio.',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('new_order'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );
}

/// FLAG_INSISTENT de Android: el sonido se repite hasta que se toca o se descarta el aviso.
const _insistent = 4;
const _alarmId = 7100;

/// Avisos locales: crea los canales y muestra la alarma, que llega como push solo de datos
/// para que la app decida cómo sonar (con la app cerrada, desde el isolate de fondo).
abstract final class LocalAlerts {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Sin Firebase (tests, modo demo) nunca se inicializa y no hay nada que cancelar.
  static var _ready = false;

  /// [onTap] recibe los datos del aviso que el usuario tocó con la app abierta o en segundo plano.
  static Future<void> init({void Function(Map<String, String> data)? onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => onTap?.call(decodePayload(response.payload)),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(PushChannels.orders);
    await android?.createNotificationChannel(PushChannels.orderAlarm);
    _ready = true;
  }

  /// Datos del aviso con el que se abrió la app (si la abrió un aviso local).
  static Future<Map<String, String>?> launchData() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return decodePayload(details.notificationResponse?.payload);
  }

  static Future<void> showAlarm(Map<String, String> data) => _plugin.show(
    id: _alarmId,
    title: data['title'] ?? 'Pedido nuevo',
    body: data['body'],
    payload: jsonEncode(data),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        PushChannels.orderAlarm.id,
        PushChannels.orderAlarm.name,
        channelDescription: PushChannels.orderAlarm.description,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        sound: PushChannels.orderAlarm.sound,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: Int32List.fromList([_insistent]),
        ticker: 'Pedido nuevo',
      ),
    ),
  );

  /// Al abrir la app ya no hace falta que suene: el pedido se ve en el tablero.
  static Future<void> cancelAlarm() async {
    if (_ready) await _plugin.cancel(id: _alarmId);
  }

  static Map<String, String> decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return const {};
    try {
      return (jsonDecode(payload) as Map<String, dynamic>).map((key, value) => MapEntry(key, '$value'));
    } on FormatException {
      return const {};
    }
  }
}
