import 'dart:async';

import 'package:apamuy/core/errors/app_exception.dart';
import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/core/utils/text_utils.dart';

/// Backend fake de Apamuy Socios: pedidos de negocio y repartidor compartidos en
/// memoria, con el JSON de `merchant/*` y `courier/*`. Cada [newOrderEvery] entra uno.
class FakeStaffOrders {
  FakeStaffOrders(this._backend, {this.newOrderEvery = const Duration(seconds: 45)});

  static const merchantStoreId = 'st_chaski_dorado';
  static const _courierId = 'cr_luis';

  final FakeBackend _backend;

  /// `Duration.zero` desactiva los pedidos automáticos (tests).
  final Duration newOrderEvery;

  final Map<String, Map<String, dynamic>> _orders = {};
  final Map<String, bool> _productAvailable = {};
  var _acceptingOrders = true;
  var _courierStatus = 'OFFLINE';
  var _nextCode = 3101;
  var _nextId = 0;
  Timer? _ticker;
  Future<void>? _seeding;

  static const _customers = [
    ('Alex Quispe', '984123456', 'Casa', 'Jr. Túpac Amaru 214', 'Puerta verde'),
    ('Marisol Huamán', '987654321', 'Trabajo', 'Av. Garcilaso 530', 'Frente al mercado'),
    ('Kevin Condori', '951357246', 'Casa', 'Jr. Bolognesi 118', 'Segundo piso'),
  ];

  void dispose() => _ticker?.cancel();

  Future<void> _ready() => _seeding ??= _seed();

  Future<void> _seed() async {
    final now = DateTime.now();
    await _add(merchantStoreId, status: 'RECEIVED', placed: now.subtract(const Duration(minutes: 1)), customer: 0);
    await _add(merchantStoreId, status: 'PREPARING', placed: now.subtract(const Duration(minutes: 12)), customer: 1);
    await _add(merchantStoreId, status: 'READY', placed: now.subtract(const Duration(minutes: 25)), customer: 2);
    await _add('st_pizzeria_qori', status: 'READY', placed: now.subtract(const Duration(minutes: 18)), customer: 1);
    await _add(merchantStoreId, status: 'DELIVERED', placed: now.subtract(const Duration(hours: 2)), customer: 1);
    await _add(merchantStoreId, status: 'CANCELLED', placed: now.subtract(const Duration(hours: 3)), customer: 2);
    if (newOrderEvery > Duration.zero) {
      _ticker = Timer.periodic(newOrderEvery, (_) {
        if (_acceptingOrders) {
          _add(merchantStoreId, status: 'RECEIVED', placed: DateTime.now(), customer: _nextId % _customers.length).ignore();
        }
      });
    }
  }

  static const _progression = ['RECEIVED', 'CONFIRMED', 'PREPARING', 'READY', 'COURIER_ASSIGNED', 'ON_THE_WAY', 'DELIVERED'];

  Future<void> _add(String storeId, {required String status, required DateTime placed, required int customer}) async {
    final catalog = await _backend.catalog();
    final store = _backend.listOf(catalog, 'stores').firstWhere((s) => s['id'] == storeId);
    final products = _backend.listOf(catalog, 'products').where((p) => p['storeId'] == storeId).toList();
    final n = _nextId++;
    final picks = [products[n % products.length], if (products.length > 1) products[(n + 1) % products.length]];
    final lines = [
      for (final (i, p) in picks.indexed)
        {
          'productId': p['id'],
          'name': p['name'],
          'quantity': i == 0 ? 1 : 2,
          'total': _backend.money((p['basePrice'] as int) * (i == 0 ? 1 : 2)),
          'description': '',
          'notes': i == 0 && n.isEven ? 'Sin ají, por favor' : '',
        },
    ];
    final subtotal = lines.fold<int>(0, (sum, l) => sum + ((l['total']! as Map)['amount'] as int));
    final fee = store['deliveryFee'] as int;
    final (name, phone, title, street, ref) = _customers[customer];
    final cash = n.isEven;
    final total = subtotal + fee;
    final reached = status == 'CANCELLED' ? 1 : _progression.indexOf(status) + 1;
    final storeLat = (store['latitude'] as num).toDouble();
    final storeLng = (store['longitude'] as num).toDouble();
    final order = <String, dynamic>{
      'id': 'ord_staff_$n',
      'code': '#${_nextCode++}',
      'store': {'id': store['id'], 'name': store['name'], 'logoUrl': store['logoUrl'], 'ownerName': store['ownerName']},
      'lines': lines,
      'subtotal': _backend.money(subtotal),
      'deliveryFee': _backend.money(fee),
      'discount': _backend.money(0),
      'tip': _backend.money(0),
      'total': _backend.money(total),
      'notes': n % 3 == 0 ? 'Tocar el timbre dos veces' : '',
      'address': {'title': title, 'street': street, 'reference': ref},
      'payment': cash
          ? {'type': 'CASH', 'changeFor': _backend.money(((total ~/ 5000) + 1) * 5000)}
          : {'type': 'YAPE', 'changeFor': null},
      'status': status,
      'events': [
        for (final (i, st) in _progression.take(reached).indexed)
          {'status': st, 'at': placed.add(Duration(minutes: i * 4)).toUtc().toIso8601String()},
        if (status == 'CANCELLED') {'status': 'CANCELLED', 'at': placed.add(const Duration(minutes: 3)).toUtc().toIso8601String()},
      ],
      'placedAt': placed.toUtc().toIso8601String(),
      'courier': null,
      'estimatedArrival': placed.add(const Duration(minutes: 40)).toUtc().toIso8601String(),
      'scheduledFor': null,
      'rating': null,
      'customer': {'name': name, 'phone': phone},
      'deliveryLocation': {'lat': storeLat + 0.004 * (customer + 1), 'lng': storeLng - 0.003},
      'pickup': {
        'address': store['addressLine'],
        'phone': store['phone'],
        'location': {'lat': storeLat, 'lng': storeLng},
      },
      'distanceMeters': 600 + 350 * customer,
      'cancelReason': status == 'CANCELLED' ? 'Sin stock: Pollo entero a la brasa' : null,
      'collection': null,
      // Internos del fake (no son parte del contrato).
      '_courierId': null,
    };
    if (status == 'DELIVERED') {
      order['collection'] = {'method': cash ? 'CASH' : 'YAPE', 'amount': _backend.money(total), 'collectedAt': placed.add(const Duration(minutes: 35)).toUtc().toIso8601String()};
      order['_courierId'] = _courierId;
      order['courier'] = _courierJson;
    }
    _orders[order['id'] as String] = order;
  }

  static const Map<String, Object?> _courierJson = {'name': 'Luis Quispe', 'vehicle': 'Moto roja', 'since': 2023, 'avatarUrl': null};

  Map<String, dynamic> _public(Map<String, dynamic> order) =>
      {for (final e in order.entries) if (!e.key.startsWith('_')) e.key: e.value};

  Map<String, dynamic> _find(String id) =>
      _orders[id] ?? (throw const ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'No encontramos ese pedido.'));

  List<Map<String, dynamic>> _sorted(Iterable<Map<String, dynamic>> orders) =>
      (orders.toList()..sort((a, b) => (b['placedAt'] as String).compareTo(a['placedAt'] as String))).map(_public).toList();

  static bool _isToday(Map<String, dynamic> o) {
    final placed = DateTime.parse(o['placedAt'] as String).toLocal();
    final now = DateTime.now();
    return placed.year == now.year && placed.month == now.month && placed.day == now.day;
  }

  static bool _isActive(Map<String, dynamic> o) => o['status'] != 'DELIVERED' && o['status'] != 'CANCELLED';

  bool Function(Map<String, dynamic>) _scope(String? scope) => switch (scope) {
    'active' => _isActive,
    'today' => _isToday,
    _ => (_) => true,
  };

  void _move(Map<String, dynamic> order, String to) {
    order['status'] = to;
    (order['events'] as List).add({'status': to, 'at': DateTime.now().toUtc().toIso8601String()});
  }

  Never _invalid(Map<String, dynamic> order, String to) => throw ApiException(
    statusCode: 409,
    code: 'INVALID_STATUS_TRANSITION',
    message: 'El pedido ya cambió de estado. Actualiza la lista.',
    details: {'from': order['status'], 'to': to},
  );

  Future<List<Map<String, dynamic>>> merchantStores() async {
    await _backend.delay();
    await _ready();
    final store = _backend.listOf(await _backend.catalog(), 'stores').firstWhere((s) => s['id'] == merchantStoreId);
    return [
      {'id': store['id'], 'name': store['name'], 'logoUrl': store['logoUrl'], 'isAcceptingOrders': _acceptingOrders, 'isOpenNow': true},
    ];
  }

  Future<Map<String, dynamic>> setAcceptingOrders(String storeId, {required bool accepting}) async {
    await _backend.delay();
    if (storeId != merchantStoreId) throw const ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'No encontramos ese negocio.');
    _acceptingOrders = accepting;
    return {'id': storeId, 'name': 'Pollería El Chaski Dorado', 'isAcceptingOrders': accepting};
  }

  Future<List<Map<String, dynamic>>> merchantOrders({String? scope}) async {
    await _backend.delay();
    await _ready();
    final filter = _scope(scope);
    return _sorted(_orders.values.where((o) => (o['store'] as Map)['id'] == merchantStoreId && filter(o)));
  }

  static const _boardColumns = {
    'fresh': {'RECEIVED'},
    'cooking': {'CONFIRMED', 'PREPARING'},
    'ready': {'READY', 'COURIER_ASSIGNED', 'ON_THE_WAY'},
  };

  /// Como `GET /merchant/board`: los pedidos en curso en sus tres columnas.
  Future<Map<String, dynamic>> merchantBoard() async {
    final active = await merchantOrders(scope: 'active');
    return {
      'columns': [
        for (final MapEntry(:key, value: statuses) in _boardColumns.entries)
          {
            'key': key,
            'count': active.where((o) => statuses.contains(o['status'])).length,
            'items': active.where((o) => statuses.contains(o['status'])).toList(),
          },
      ],
    };
  }

  Future<Map<String, dynamic>> accept(String id, {required int prepMinutes}) async {
    await _backend.delay();
    final order = _find(id);
    if (order['status'] != 'RECEIVED') _invalid(order, 'CONFIRMED');
    _move(order, 'CONFIRMED');
    _move(order, 'PREPARING');
    order['estimatedArrival'] = DateTime.now().add(Duration(minutes: prepMinutes + 15)).toUtc().toIso8601String();
    return _public(order);
  }

  Future<Map<String, dynamic>> markReady(String id) async {
    await _backend.delay();
    final order = _find(id);
    if (order['status'] != 'PREPARING') _invalid(order, 'READY');
    _move(order, 'READY');
    return _public(order);
  }

  Future<Map<String, dynamic>> reject(String id, {required String reason}) async {
    await _backend.delay();
    final order = _find(id);
    if (!const ['RECEIVED', 'CONFIRMED', 'PREPARING', 'READY'].contains(order['status'])) _invalid(order, 'CANCELLED');
    _move(order, 'CANCELLED');
    order['cancelReason'] = reason;
    return _public(order);
  }

  /// Como `GET /merchant/stores/:id/products`: conteos de toda la carta y
  /// los productos del filtro y la búsqueda, agrupados en el orden del menú.
  Future<Map<String, dynamic>> products(String storeId, {String status = 'all', String query = ''}) async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    final store = _backend.listOf(catalog, 'stores').firstWhere(
      (s) => s['id'] == storeId,
      orElse: () => throw const ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'No encontramos ese negocio.'),
    );
    final menu = (store['menuSections'] as List).cast<Map<String, dynamic>>();
    final all = [
      for (final p in _backend.listOf(catalog, 'products').where((p) => p['storeId'] == storeId))
        {
          'id': p['id'],
          'name': p['name'],
          'imageUrl': p['imageUrl'],
          'price': _backend.money(p['basePrice'] as int),
          'section': menu.where((s) => (s['productIds'] as List).contains(p['id'])).firstOrNull?['name'] as String?,
          'isAvailable': _productAvailable[p['id']] ?? (p['isAvailable'] as bool? ?? true),
        },
    ];
    final needle = normalizeForSearch(query);
    final shown = [
      for (final p in all)
        if (foldAccents(p['name']! as String).contains(needle) &&
            switch (status) {
              'available' => p['isAvailable']! as bool,
              'sold_out' => !(p['isAvailable']! as bool),
              _ => true,
            })
          p,
    ];
    final available = all.where((p) => p['isAvailable']! as bool).length;
    return {
      'counts': {'all': all.length, 'available': available, 'soldOut': all.length - available},
      'sections': [
        for (final section in [...menu.map((s) => s['name'] as String), null])
          if (shown.where((p) => p['section'] == section).toList() case final items when items.isNotEmpty)
            {'name': section ?? 'Otros', 'items': items},
      ],
    };
  }

  Future<Map<String, dynamic>> setProductAvailable(String productId, {required bool available}) async {
    await _backend.delay();
    _productAvailable[productId] = available;
    return {'id': productId, 'isAvailable': available};
  }

  Future<Map<String, dynamic>> merchantSummary() async {
    await _backend.delay();
    await _ready();
    final today = _orders.values.where((o) => (o['store'] as Map)['id'] == merchantStoreId && _isToday(o)).toList();
    final delivered = today.where((o) => o['status'] == 'DELIVERED');
    // Un día de ejemplo para que la demo tenga gráficas; lo entregado en la
    // demo se suma encima. El backend real calcula todo con sus pedidos.
    int cents(Map<String, dynamic> o) => (o['subtotal'] as Map)['amount'] as int;
    final hours = {for (final (hour, sales) in _sampleHours) hour: sales};
    final payments = {'CASH': 22800, 'YAPE': 19650, 'PLIN': 6200};
    final products = {for (final (name, qty) in _sampleProducts) name: qty};
    for (final o in delivered) {
      final hour = DateTime.parse(o['placedAt'] as String).toLocal().hour;
      hours[hour] = (hours[hour] ?? 0) + cents(o);
      final method = (o['payment'] as Map)['type'] as String;
      payments[method] = (payments[method] ?? 0) + cents(o);
      for (final line in (o['lines'] as List).cast<Map<String, dynamic>>()) {
        products[line['name'] as String] = (products[line['name']] ?? 0) + (line['quantity'] as int);
      }
    }
    final deliveredCount = 22 + delivered.length;
    final sales = hours.values.fold<int>(0, (a, b) => a + b);
    final first = hours.keys.reduce((a, b) => a < b ? a : b);
    final last = hours.keys.reduce((a, b) => a > b ? a : b);
    final byHour = [for (var h = first; h <= last; h++) (h, hours[h] ?? 0)];
    final peak = byHour.reduce((a, b) => b.$2 > a.$2 ? b : a).$1;
    final shares = {for (final e in payments.entries) e.key: (e.value * 100 / sales).floor()};
    shares['CASH'] = shares['CASH']! + 100 - shares.values.fold<int>(0, (a, b) => a + b);
    final top = products.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {
      'date': _today(),
      'deliveredCount': deliveredCount,
      'cancelledCount': 1 + today.where((o) => o['status'] == 'CANCELLED').length,
      'activeCount': today.where(_isActive).length,
      'sales': _backend.money(sales),
      'averageTicket': _backend.money(sales ~/ deliveredCount),
      'averagePrepMinutes': 14,
      'peakHour': peak,
      'salesByHour': [
        for (final (hour, cents) in byHour) {'hour': hour, 'sales': _backend.money(cents), 'orders': cents ~/ 2100},
      ],
      'payments': [
        for (final e in payments.entries)
          {'method': e.key, 'sales': _backend.money(e.value), 'orders': e.value ~/ 2100, 'share': shares[e.key]},
      ],
      'topProducts': [
        for (final e in top.take(5))
          {'productId': null, 'name': e.key, 'quantity': e.value, 'sales': _backend.money(e.value * 1500)},
      ],
    };
  }

  static const _sampleHours = [
    (11, 1850), (12, 6400), (13, 9850), (14, 7200), (15, 2100), (16, 800),
    (17, 1200), (18, 3500), (19, 5750), (20, 6100), (21, 3050), (22, 850),
  ];

  static const _sampleProducts = [
    ('1/4 pollo a la brasa', 14),
    ('Caldo de cordero', 9),
    ('Chicha morada 1 L', 7),
    ('Papas fritas', 6),
    ('Ensalada fresca', 4),
  ];

  Map<String, dynamic>? get _activeDelivery => _orders.values
      .where((o) => o['_courierId'] == _courierId && (o['status'] == 'COURIER_ASSIGNED' || o['status'] == 'ON_THE_WAY'))
      .firstOrNull;

  Map<String, dynamic> _courier() => {
    'id': _courierId,
    'name': 'Luis Quispe',
    'phone': '900000101',
    'vehicleLabel': 'Moto roja',
    'status': _courierStatus,
    'activeOrderId': _activeDelivery?['id'],
  };

  Future<Map<String, dynamic>> courierMe() async {
    await _backend.delay();
    await _ready();
    return _courier();
  }

  Future<Map<String, dynamic>> setCourierStatus(String status) async {
    await _backend.delay();
    await _ready();
    if (_activeDelivery != null) {
      if (status == 'OFFLINE') {
        throw const ApiException(
          statusCode: 409,
          code: 'COURIER_HAS_ACTIVE_ORDER',
          message: 'Termina tu entrega antes de desconectarte.',
        );
      }
    } else {
      _courierStatus = status;
    }
    return _courier();
  }

  Future<List<Map<String, dynamic>>> availableOrders() async {
    await _backend.delay();
    await _ready();
    if (_courierStatus != 'AVAILABLE') return const [];
    return _sorted(_orders.values.where((o) => o['status'] == 'READY' && o['_courierId'] == null));
  }

  Future<List<Map<String, dynamic>>> courierOrders({String? scope}) async {
    await _backend.delay();
    await _ready();
    final filter = _scope(scope);
    return _sorted(_orders.values.where((o) => o['_courierId'] == _courierId && filter(o)));
  }

  Future<Map<String, dynamic>> acceptDelivery(String id) async {
    await _backend.delay();
    final order = _find(id);
    if (_courierStatus != 'AVAILABLE' || _activeDelivery != null) {
      throw const ApiException(
        statusCode: 409,
        code: 'COURIER_NOT_AVAILABLE',
        message: 'Conéctate y termina tu entrega actual antes de tomar otro pedido.',
      );
    }
    if (order['status'] != 'READY' || order['_courierId'] != null) {
      throw const ApiException(statusCode: 409, code: 'ORDER_ALREADY_TAKEN', message: 'Otro repartidor ya tomó este pedido.');
    }
    order
      ..['_courierId'] = _courierId
      ..['courier'] = _courierJson;
    _move(order, 'COURIER_ASSIGNED');
    _courierStatus = 'BUSY';
    return _public(order);
  }

  Future<Map<String, dynamic>> pickedUp(String id) async {
    await _backend.delay();
    final order = _find(id);
    if (order['status'] != 'COURIER_ASSIGNED' || order['_courierId'] != _courierId) _invalid(order, 'ON_THE_WAY');
    _move(order, 'ON_THE_WAY');
    return _public(order);
  }

  Future<Map<String, dynamic>> delivered(String id, {required String method, required Map<String, Object?> amount}) async {
    await _backend.delay();
    final order = _find(id);
    if (order['status'] != 'ON_THE_WAY' || order['_courierId'] != _courierId) _invalid(order, 'DELIVERED');
    _move(order, 'DELIVERED');
    order['collection'] = {'method': method, 'amount': amount, 'collectedAt': DateTime.now().toUtc().toIso8601String()};
    _courierStatus = 'AVAILABLE';
    return _public(order);
  }

  Future<Map<String, dynamic>> courierSummary() async {
    await _backend.delay();
    await _ready();
    final delivered = _orders.values.where(
      (o) => o['_courierId'] == _courierId && o['status'] == 'DELIVERED' && o['collection'] != null && _isToday(o),
    );
    int sum(String? method) => delivered
        .where((o) => method == null || (o['collection'] as Map)['method'] == method)
        .fold<int>(0, (s, o) => s + (((o['collection'] as Map)['amount'] as Map)['amount'] as int));
    return {
      'date': _today(),
      'deliveredCount': delivered.length,
      'collected': {
        'total': _backend.money(sum(null)),
        'CASH': _backend.money(sum('CASH')),
        'YAPE': _backend.money(sum('YAPE')),
        'PLIN': _backend.money(sum('PLIN')),
      },
    };
  }

  static String _today() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

}
