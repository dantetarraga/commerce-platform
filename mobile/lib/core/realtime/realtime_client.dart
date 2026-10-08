import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

/// Un aviso del servidor por WebSocket. Solo dice qué cambió: el detalle se
/// vuelve a pedir por REST.
final class RealtimeEvent {
  const RealtimeEvent(this.name, this.data);

  final String name;
  final Map<String, dynamic> data;

  /// `orderId` del aviso, si lo trae.
  String? get orderId => data['orderId'] as String?;
}

/// Nombres de los eventos que manda el backend (`modules/realtime`).
abstract final class RealtimeEvents {
  static const orderUpdated = 'order.updated';
  static const courierLocation = 'courier.location';
  static const storeOrdersChanged = 'store.orders.changed';
  static const courierOrdersChanged = 'courier.orders.changed';

  static const List<String> all = [orderUpdated, courierLocation, storeOrdersChanged, courierOrdersChanged];
}

/// Conexión de tiempo real de la sesión actual. Si se cae, quien la usa sigue
/// consultando por REST (más seguido mientras [isConnected] es falso).
abstract interface class RealtimeClient {
  Stream<RealtimeEvent> get events;

  bool get isConnected;

  /// Empieza a recibir `order.updated` y `courier.location` de ese pedido.
  /// Se repite solo al reconectar.
  void subscribeOrder(String orderId);

  void unsubscribeOrder(String orderId);

  Future<void> dispose();
}

/// Sin sesión o en modo demo: nunca conecta.
final class NoRealtimeClient implements RealtimeClient {
  const NoRealtimeClient();

  @override
  Stream<RealtimeEvent> get events => const Stream.empty();

  @override
  bool get isConnected => false;

  @override
  void subscribeOrder(String orderId) {}

  @override
  void unsubscribeOrder(String orderId) {}

  @override
  Future<void> dispose() async {}
}

/// Socket.IO contra `/ws`. El access token va en el handshake; si el servidor
/// lo rechaza (`UNAUTHORIZED`), se renueva la sesión y se reconecta una vez.
/// Los cortes de red los reintenta el propio Socket.IO.
final class SocketIoRealtimeClient implements RealtimeClient {
  SocketIoRealtimeClient({
    required String url,
    required Future<String?> Function() accessToken,
    required Future<void> Function() refreshSession,
  }) : _refreshSession = refreshSession {
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(15000)
          // Se pide en cada (re)conexión: así usa el token recién renovado.
          .setAuthFn((send) => unawaited(accessToken().then((token) => send({'token': token ?? ''}))))
          .build(),
    );
    _socket
      ..onConnect((_) {
        _connected = true;
        _refreshedAt = null;
        for (final orderId in _orders) {
          _socket.emit('order.subscribe', {'orderId': orderId});
        }
      })
      ..onDisconnect((_) => _connected = false)
      ..onConnectError(_onConnectError);
    for (final name in RealtimeEvents.all) {
      _socket.on(name, (data) {
        if (data is Map) _events.add(RealtimeEvent(name, Map<String, dynamic>.from(data)));
      });
    }
    _socket.connect();
  }

  /// Entre dos renovaciones por token rechazado, para no entrar en bucle.
  static const _refreshCooldown = Duration(seconds: 30);

  late final io.Socket _socket;
  final Future<void> Function() _refreshSession;
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _orders = <String>{};
  var _connected = false;
  DateTime? _refreshedAt;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  bool get isConnected => _connected;

  @override
  void subscribeOrder(String orderId) {
    if (!_orders.add(orderId)) return;
    if (_connected) _socket.emit('order.subscribe', {'orderId': orderId});
  }

  @override
  void unsubscribeOrder(String orderId) {
    if (!_orders.remove(orderId)) return;
    if (_connected) _socket.emit('order.unsubscribe', {'orderId': orderId});
  }

  Future<void> _onConnectError(dynamic error) async {
    _connected = false;
    final message = error is Map ? error['message'] : error?.toString();
    if (message != 'UNAUTHORIZED') return;
    final last = _refreshedAt;
    if (last != null && DateTime.now().difference(last) < _refreshCooldown) return;
    _refreshedAt = DateTime.now();
    try {
      await _refreshSession();
    } on Object {
      return;
    }
    if (!_events.isClosed) _socket.connect();
  }

  @override
  Future<void> dispose() async {
    _socket
      ..clearListeners()
      ..dispose();
    await _events.close();
  }
}

/// `http://host:3000/api/v1` → `http://host:3000/ws`.
String realtimeUrl(String apiBaseUrl) {
  final api = Uri.parse(apiBaseUrl);
  return Uri(scheme: api.scheme, host: api.host, port: api.hasPort ? api.port : null, path: '/ws').toString();
}
