import 'dart:convert';
import 'dart:io';

import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/features/courier_deliveries/domain/courier.dart';
import 'package:chaski/features/courier_deliveries/infrastructure/courier_repository_impl.dart';
import 'package:chaski/features/courier_deliveries/infrastructure/datasources/courier_remote_data_source.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/infrastructure/datasources/merchant_remote_data_source.dart';
import 'package:chaski/features/merchant_orders/infrastructure/models/merchant_json.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/orders/orders_infrastructure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Respuestas reales de la API (grabadas recorriendo un pedido completo contra
/// el backend local). Si el backend cambia el contrato de Chaski Socios, este
/// test lo detecta: hay que regrabarlas y ajustar la app.
Object? _fixture(String name) =>
    jsonDecode(File('test/fixtures/partner_api/$name.json').readAsStringSync());

Map<String, dynamic> _map(String name) => _fixture(name)! as Map<String, dynamic>;

List<Map<String, dynamic>> _list(String name) => (_fixture(name)! as List).cast<Map<String, dynamic>>();

class _MockCourierRemote extends Mock implements CourierRemoteDataSource {}

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  test('el pedido para socios trae notas, retiro, cliente y cobro', () {
    final order = StaffOrderJson.fromJson(_map('courier_delivered'));
    expect(order.status, OrderStatus.delivered);
    expect(order.order.lines.first.notes, 'Bien helada');
    expect(order.order.notes, 'Tocar el timbre');
    expect(order.customerPhone, '984123456');
    expect(order.pickup.phone, isNotNull);
    expect(order.distanceMeters, greaterThan(0));
    expect(order.collection?.method, CollectionMethod.cash);
    expect(order.collection?.amount, order.order.total);
  });

  test('aceptar deja el pedido en preparación con hora estimada', () {
    final order = StaffOrderJson.fromJson(_map('merchant_accept'));
    expect(order.status, OrderStatus.preparing);
    expect(order.order.estimatedArrival, isNotNull);
    expect(order.order.timeOf(OrderStatus.confirmed), isNotNull);
  });

  test('listas del negocio: pedidos, negocios, productos y resumen', () {
    final orders = (_map('merchant_orders_active')['items'] as List).cast<Map<String, dynamic>>();
    expect(orders.map(StaffOrderJson.fromJson), isNotEmpty);
    expect(_list('merchant_stores').map(MerchantJson.store).single.id, 'st_chaski_dorado');
    final catalog = MerchantJson.catalog(_map('merchant_products'));
    final products = catalog.sections.expand((s) => s.items).toList();
    expect(products, hasLength(catalog.counts.all));
    expect(products.where((p) => !p.isAvailable), hasLength(catalog.counts.soldOut));
    expect(catalog.sections.first.name, isNotEmpty);
    final summary = MerchantJson.summary(_map('merchant_summary'));
    expect(summary.sales, isA<Money>());
    expect(summary.payments.map((p) => p.kind), [PaymentKind.cash, PaymentKind.yape, PaymentKind.plin]);
  });

  test('la carta pide al backend la pestaña y la búsqueda', () async {
    final api = _MockApiClient();
    when(() => api.get(any(), query: any(named: 'query'))).thenAnswer((_) async => _map('merchant_products'));
    final remote = ApiMerchantRemoteDataSource(api);

    await remote.products('st_1', status: 'sold_out', query: '  pollo ');
    verify(() => api.get('/merchant/stores/st_1/products', query: {'status': 'sold_out', 'q': 'pollo'})).called(1);
    await remote.products('st_1');
    verify(() => api.get('/merchant/stores/st_1/products', query: {'status': 'all'})).called(1);
  });

  test('repartidor: perfil, disponibles y resumen', () async {
    final remote = _MockCourierRemote();
    when(remote.me).thenAnswer((_) async => _map('courier_me'));
    when(remote.available).thenAnswer((_) async => (_map('courier_available')['items'] as List).cast<Map<String, dynamic>>());
    when(remote.summary).thenAnswer((_) async => _map('courier_summary'));
    final repo = CourierRepositoryImpl(remote);

    final me = (await repo.me()).getOrThrow();
    expect(me.availability, CourierAvailability.available);
    expect(me.vehicleLabel, isNotEmpty);
    expect((await repo.available()).getOrThrow(), isNotEmpty);
    final summary = (await repo.summary()).getOrThrow();
    expect(summary.deliveredCount, greaterThan(0));
    expect(summary.cash.cents, summary.total.cents - summary.yape.cents - summary.plin.cents);
  });
}
