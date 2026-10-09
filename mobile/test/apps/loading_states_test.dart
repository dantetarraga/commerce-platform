import 'dart:io';

import 'package:apamuy/apps/customer/router/app_router.dart';
import 'package:apamuy/features/stores/stores.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/design_capture.dart';

const _capture = bool.fromEnvironment('CAPTURE_LOADING');
const _latency = Duration(seconds: 3);

Future<void> _shot(WidgetTester tester, String name) async {
  if (!_capture) return;
  await expectLater(
    find.byType(Overlay).first,
    matchesGoldenFile('../../../docs/ui/carga/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    await loadDesignFonts();
    final cache = Directory.systemTemp.createTempSync('apamuy_loading_ui_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => cache.path,
        );
  });

  Future<void> sequence(WidgetTester tester, String name) async {
    for (var i = 0; i < 4; i++) {
      await _shot(tester, '${name}_$i');
      await tester.pump(_latency);
      await settle(tester);
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await settle(tester);
    await _shot(tester, '${name}_listo');
  }

  testWidgets('cliente: inicio', (tester) async {
    final c = await pumpApamuy(tester, signedIn: true, latency: _latency);
    await sequence(tester, 'cliente_inicio');
    await unmountApamuy(tester, c);
  });

  testWidgets('cliente: pedidos y negocio', (tester) async {
    final c = await pumpApamuy(tester, signedIn: true, latency: _latency);
    for (var i = 0; i < 3; i++) {
      await tester.pump(_latency);
      await settle(tester);
    }
    final stores = c.read(storesProvider()).value!.items;
    final store = stores.where((s) => s.isOpenNow).first;
    c.read(appRouterProvider).go('/pedidos');
    await settle(tester);
    await _shot(tester, 'cliente_pedidos_0');
    await tester.pump(_latency * 2);
    await settle(tester);
    await _shot(tester, 'cliente_pedidos_listo');
    c.read(appRouterProvider).go('/negocio/${store.id}');
    await settle(tester);
    await _shot(tester, 'cliente_negocio_0');
    await tester.pump(_latency);
    await settle(tester);
    await _shot(tester, 'cliente_negocio_1');
    for (var i = 0; i < 3; i++) {
      await tester.pump(_latency);
      await settle(tester);
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
    await _shot(tester, 'cliente_negocio_listo');
    await unmountApamuy(tester, c);
  });

  testWidgets('negocio: comandas', (tester) async {
    final c = await pumpPartner(
      tester,
      signedInAs: 'usr_owner_chaski_dorado',
      latency: _latency,
    );
    await sequence(tester, 'negocio');
    await unmountApamuy(tester, c);
  });

  testWidgets('negocio: riel en tablet', (tester) async {
    final c = await pumpPartner(
      tester,
      signedInAs: 'usr_owner_chaski_dorado',
      latency: _latency,
      size: const Size(1024, 768),
      brightness: Brightness.dark,
    );
    await sequence(tester, 'negocio_tablet');
    await unmountApamuy(tester, c);
  });

  testWidgets('repartidor: recorridos', (tester) async {
    final c = await pumpPartner(
      tester,
      signedInAs: 'usr_courier_luis',
      latency: _latency,
    );
    await sequence(tester, 'repartidor');
    await unmountApamuy(tester, c);
  });
}
