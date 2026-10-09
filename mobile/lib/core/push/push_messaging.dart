/// Qué app registra el teléfono: el backend manda la alarma de pedidos solo a Socios.
enum PushApp {
  customer('customer'),
  partner('partner');

  const PushApp(this.wire);

  /// Valor de `app` en `PUT /users/me/devices`.
  final String wire;
}

/// Push del teléfono detrás de una interfaz: Firebase en el dispositivo, nada en
/// tests, en el modo demo o si la app se compiló sin `google-services.json`.
abstract interface class PushMessaging {
  /// Token del dispositivo, o `null` si no hay push (sin permiso o sin Firebase).
  Future<String?> token();

  /// FCM renovó el token: hay que volver a registrarlo.
  Stream<String> get onTokenRefresh;

  /// Los `data` de un aviso que el usuario tocó (también el que abrió la app).
  Stream<Map<String, String>> get onOpened;
}

class NoopPushMessaging implements PushMessaging {
  const NoopPushMessaging();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, String>> get onOpened => const Stream.empty();
}
