import 'dart:convert';
import 'dart:io';

import 'package:chaski/core/domain/money.dart';
import 'package:chaski/features/courier_deliveries/domain/courier.dart';
import 'package:chaski/features/courier_deliveries/infrastructure/courier_repository_impl.dart';
import 'package:chaski/features/courier_deliveries/infrastructure/datasources/courier_remote_data_source.dart';
import 'package:chaski/features/merchant_orders/infrastructure/models/merchant_json.dart';
import 'package:chaski/features/orders/orders.dart';
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
    final products = _list('merchant_products').map(MerchantJson.product).toList();
    expect(products.where((p) => !p.isAvailable), isNotEmpty);
    expect(products.first.section, isNotNull);
    expect(MerchantJson.summary(_map('merchant_summary')).sales, isA<Money>());
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
