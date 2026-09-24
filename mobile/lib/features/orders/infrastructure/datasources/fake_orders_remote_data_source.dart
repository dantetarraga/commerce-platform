import 'dart:async';

import 'package:chaski/core/errors/app_exception.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/features/orders/infrastructure/datasources/orders_remote_data_source.dart';

/// Simula `/orders` en memoria. Un pedido nuevo avanza solo por los estados
/// (cada [FakeBackend.orderStep]) para que el seguimiento se vea vivo en demo.
///
/// Arranca con dos pedidos entregados para que "Volver a pedir" y el historial
/// tengan contenido.
class FakeOrdersRemoteDataSource implements OrdersRemoteDataSource {
  FakeOrdersRemoteDataSource(this._backend);

  final FakeBackend _backend;
  final Map<String, Map<String, dynamic>> _orders = {};
  final _changes = StreamController<Map<String, dynamic>>.broadcast();
  final List<Timer> _timers = [];
  var _seeded = false;
  var _nextCode = 2481;

  static const _progression = ['RECEIVED', 'CONFIRMED', 'PREPARING', 'READY', 'COURIER_ASSIGNED', 'ON_THE_WAY', 'DELIVERED'];

  /// Cuánto dura cada estado, en "pasos" (preparar tarda más que confirmar).
  static const _stepsPerStatus = {'RECEIVED': 1, 'CONFIRMED': 1, 'PREPARING': 3, 'READY': 1, 'COURIER_ASSIGNED': 1, 'ON_THE_WAY': 3};

  static const List<Map<String, Object?>> _couriers = [
    {'name': 'Luis Quispe', 'vehicle': 'Moto roja', 'since': 2023, 'avatarUrl': null},
    {'name': 'Yeni Mamani', 'vehicle': 'Moto azul', 'since': 2022, 'avatarUrl': null},
  ];

  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _changes.close().ignore();
  }

  Future<void> _seed() async {
    if (_seeded) return;
    _seeded = true;
    final catalog = await _backend.catalog();
    final stores = _backend.listOf(catalog, 'stores');
    final products = _backend.listOf(catalog, 'products');
    Map<String, dynamic>? store(String id) => stores.where((s) => s['id'] == id).firstOrNull;
    Map<String, dynamic>? product(String id) => products.where((p) => p['id'] == id).firstOrNull;

    void add(String storeId, List<(String, int)> items, Duration ago, int rating) {
      final s = store(storeId);
      if (s == null) return;
      final lines = [
        for (final (id, qty) in items)
          if (product(id) case final p?) _line(p, qty, p['basePrice'] as int, ''),
      ];
      final placed = DateTime.now().subtract(ago);
      final order = _build(s, lines, placed, couponCents: 0, address: _demoAddress, payment: {'type': 'YAPE'}, scheduledFor: null)
        ..['status'] = 'DELIVERED'
        ..['rating'] = rating
        ..['courier'] = _couriers[1]
        ..['events'] = [
          for (final (i, st) in _progression.indexed) {'status': st, 'at': placed.add(Duration(minutes: i * 6)).toUtc().toIso8601String()},
        ];
      _orders[order['id'] as String] = order;
    }

    add('st_dona_rosa', [('pr_caldo_cordero', 2), ('pr_mate_coca', 1)], const Duration(days: 2, hours: 3), 3);
    add('st_tanta_wasi', [('pr_pan_chuta', 1), ('pr_pan_anis', 1)], const Duration(days: 5, hours: 1), 3);
  }

  static const _demoAddress = {'title': 'Casa', 'street': 'Jr. Túpac Amaru 214', 'reference': 'Puerta verde'};

  Map<String, dynamic> _line(Map<String, dynamic> p, int qty, int unit, String description) => {
    'productId': p['id'],
    'name': p['name'],
    'quantity': qty,
    'total': _backend.money(unit * qty),
    'description': description,
  };

  Map<String, dynamic> _build(
    Map<String, dynamic> store,
    List<Map<String, dynamic>> lines,
    DateTime placed, {
    required int couponCents,
    required Map<String, Object?> address,
    required Map<String, Object?> payment,
    required String? scheduledFor,
    int tipCents = 0,
    String notes = '',
  }) {
    final subtotal = lines.fold<int>(0, (sum, l) => sum + ((l['total'] as Map)['amount'] as int));
    final fee = store['deliveryFee'] as int;
    final discount = couponCents > subtotal ? subtotal : couponCents;
    // La propina nunca es negativa ni absurda (tope S/ 50).
    final tip = tipCents.clamp(0, 5000);
    final id = 'ord_${placed.microsecondsSinceEpoch}';
    return {
      'id': id,
      'code': '#${_nextCode++}',
      'store': {
        'id': store['id'],
        'name': store['name'],
        'logoUrl': store['logoUrl'],
        'ownerName': store['ownerName'],
      },
      'lines': lines,
      'subtotal': _backend.money(subtotal),
      'deliveryFee': _backend.money(fee),
      'discount': _backend.money(discount),
      'tip': _backend.money(tip),
      'total': _backend.money(subtotal + fee - discount + tip),
      'notes': notes,
      'address': address,
      'payment': payment,
      'status': 'RECEIVED',
      'events': [
        {'status': 'RECEIVED', 'at': placed.toUtc().toIso8601String()},
      ],
      'placedAt': placed.toUtc().toIso8601String(),
      'courier': null,
      'estimatedArrival': placed.add(Duration(minutes: store['etaMinutes'] as int)).toUtc().toIso8601String(),
      'scheduledFor': scheduledFor,
      'rating': null,
    };
  }

  @override
  Future<Map<String, dynamic>> place(Map<String, Object?> body) async {
    await _backend.delay();
    await _seed();
    final catalog = await _backend.catalog();
    final store = _backend.listOf(catalog, 'stores').where((s) => s['id'] == body['storeId']).firstOrNull;
    if (store == null) {
      throw const ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'Este negocio ya no está disponible.');
    }
    final scheduledFor = body['scheduledFor'] as String?;
    if (store['isOpenNow'] != true && !_opensFor(store, scheduledFor)) {
      throw const ApiException(statusCode: 409, code: 'STORE_CLOSED', message: 'El negocio cerró hace un momento. Tu bolsa sigue guardada.');
    }
    final products = _backend.listOf(catalog, 'products');
    final lines = <Map<String, dynamic>>[];
    for (final item in (body['items']! as List).cast<Map<String, Object?>>()) {
      final p = products.where((x) => x['id'] == item['productId']).firstOrNull;
      if (p == null || p['isAvailable'] != true) {
        throw const ApiException(statusCode: 409, code: 'PRODUCT_UNAVAILABLE', message: 'Un producto de tu bolsa se agotó.');
      }
      // Recalcula el precio como lo haría el backend.
      final variants = (p['variants'] as List).cast<Map<String, dynamic>>();
      final variant = variants.where((v) => v['id'] == item['variantId']).firstOrNull;
      var unit = (variant?['price'] ?? p['basePrice']) as int;
      final labels = <String>[if (variant != null) variant['name'] as String];
      final valueIds = (item['optionValueIds']! as List).cast<String>();
      for (final option in (p['options'] as List).cast<Map<String, dynamic>>()) {
        for (final value in (option['values'] as List).cast<Map<String, dynamic>>()) {
          if (valueIds.contains(value['id'])) {
            unit += value['priceDelta'] as int;
            labels.add(value['name'] as String);
          }
        }
      }
      lines.add(_line(p, item['quantity']! as int, unit, labels.join(' · ')));
    }
    final subtotal = lines.fold<int>(0, (sum, l) => sum + ((l['total'] as Map)['amount'] as int));
    if (subtotal < (store['minOrderAmount'] as int)) {
      throw const ApiException(statusCode: 422, code: 'MIN_ORDER_NOT_REACHED', message: 'Aún no llegas al pedido mínimo.');
    }
    final coupon = switch ((body['couponCode'] as String?)?.toUpperCase()) {
      'BIENVENIDA' when subtotal >= 1500 => 500,
      'ESPINAR' => 300,
      _ => 0,
    };
    final address = body['address']! as Map<String, Object?>;
    final order = _build(
      store,
      lines,
      DateTime.now(),
      couponCents: coupon,
      address: {'title': address['title'], 'street': address['street'], 'reference': address['reference']},
      payment: body['payment']! as Map<String, Object?>,
      scheduledFor: scheduledFor,
      tipCents: ((body['tip'] as Map?)?['amount'] as int?) ?? 0,
      notes: body['notes'] as String? ?? '',
    );
    _orders[order['id'] as String] = order;
    _scheduleProgression(order['id'] as String);
    return Map.of(order);
  }

  /// Un negocio cerrado acepta el pedido si viene programado para una hora
  /// futura en la que ya atiende (según su horario semanal).
  bool _opensFor(Map<String, dynamic> store, String? scheduledFor) {
    if (scheduledFor == null) return false;
    final at = DateTime.tryParse(scheduledFor)?.toLocal();
    if (at == null || !at.isAfter(DateTime.now())) return false;
    final minutes = at.hour * 60 + at.minute;
    final day = at.weekday % 7;
    final previous = (day + 6) % 7;
    for (final h in (store['schedules'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final opens = h['opensAt'] as int;
      final closes = h['closesAt'] as int;
      final crosses = closes < opens;
      if (h['dayOfWeek'] == day && minutes >= opens && (crosses || minutes < closes)) return true;
      // Turno de ayer que cruza la medianoche.
      if (crosses && h['dayOfWeek'] == previous && minutes < closes) return true;
    }
    return false;
  }

  void _scheduleProgression(String id) {
    var elapsedSteps = 0;
    for (var i = 1; i < _progression.length; i++) {
      elapsedSteps += _stepsPerStatus[_progression[i - 1]] ?? 1;
      final status = _progression[i];
      _timers.add(Timer(_backend.orderStep * elapsedSteps, () => _advance(id, status)));
    }
  }

  void _advance(String id, String status) {
    final order = _orders[id];
    if (order == null || order['status'] == 'CANCELLED') return;
    final now = DateTime.now();
    order
      ..['status'] = status
      ..['events'] = [
        ...(order['events'] as List),
        {'status': status, 'at': now.toUtc().toIso8601String()},
      ];
    if (status == 'COURIER_ASSIGNED') order['courier'] = _couriers[_nextCode % _couriers.length];
    if (status == 'ON_THE_WAY') {
      order['estimatedArrival'] = now.add(_backend.orderStep * 3).toUtc().toIso8601String();
    }
    if (!_changes.isClosed) _changes.add(Map.of(order));
  }

  @override
  Future<Map<String, dynamic>> get(String orderId) async {
    await _backend.delay();
    await _seed();
    final order = _orders[orderId];
    if (order == null) throw const ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'No encontramos ese pedido.');
    return Map.of(order);
  }

  @override
  Future<List<Map<String, dynamic>>> list() async {
    await _backend.delay();
    await _seed();
    final all = _orders.values.map(Map<String, dynamic>.of).toList()
      ..sort((a, b) => (b['placedAt'] as String).compareTo(a['placedAt'] as String));
    return all;
  }

  @override
  Future<Map<String, dynamic>> rate(String orderId, {required int rating, required String comment}) async {
    await _backend.delay();
    final order = _orders[orderId];
    if (order == null) throw const ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'No encontramos ese pedido.');
    order['rating'] = rating;
    return Map.of(order);
  }

  @override
  Stream<Map<String, dynamic>> watch(String orderId) async* {
    yield await get(orderId);
    yield* _changes.stream.where((o) => o['id'] == orderId);
  }
}
