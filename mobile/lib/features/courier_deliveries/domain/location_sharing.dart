/// Qué hacer con el seguimiento de la ubicación del repartidor.
enum LocationSharingStep {
  /// No corresponde compartir: se apaga si estaba corriendo.
  stop,

  /// Corresponde y la app está a la vista: se inicia.
  start,

  /// Ya corre: sigue aunque la app pase al fondo o se apague la pantalla.
  keep,

  /// Corresponde, pero la app está de fondo: Android no deja iniciar el
  /// servicio de ubicación así, se espera a que vuelva a la vista.
  wait,
}

/// Comparte su ubicación solo conectado y con un pedido en curso.
LocationSharingStep locationSharingStep({
  required bool online,
  required String? activeOrderId,
  required bool foreground,
  required bool running,
}) {
  if (!online || activeOrderId == null) return LocationSharingStep.stop;
  if (running) return LocationSharingStep.keep;
  return foreground ? LocationSharingStep.start : LocationSharingStep.wait;
}

/// Lo que ve el repartidor sobre su ubicación mientras lleva un pedido.
enum CourierLocationStatus {
  /// Sin pedido, desconectado o aún sin empezar.
  idle,
  sharing,

  /// Negó el permiso; se le puede volver a pedir.
  denied,

  /// Lo negó para siempre: solo desde los ajustes.
  blocked,
  gpsOff,
}
