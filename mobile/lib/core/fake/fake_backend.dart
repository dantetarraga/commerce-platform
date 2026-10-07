import 'dart:convert';

import 'package:flutter/services.dart';

/// Utilidades de los datasources fake: devuelven el mismo JSON y lanzan las
/// mismas `ApiException` que la API, así el resto de la app no nota la diferencia.
class FakeBackend {
  FakeBackend({
    AssetBundle? bundle,
    this.latency = const Duration(milliseconds: 700),
    this.orderStep = const Duration(seconds: 6),
  }) : _bundle = bundle ?? rootBundle;

  static const _catalogAsset = 'assets/fixtures/catalog.json';

  final AssetBundle _bundle;
  final Duration latency;

  /// Duración de un "paso" en la progresión simulada de un pedido.
  final Duration orderStep;
  Map<String, dynamic>? _catalog;

  Future<Map<String, dynamic>> catalog() async {
    // Sin el caché del bundle: este objeto ya guarda el catálogo, y el caché
    // global comparte un Future entre tests que en el segundo nunca completa.
    return _catalog ??= jsonDecode(await _bundle.loadString(_catalogAsset, cache: false)) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> listOf(Map<String, dynamic> catalog, String key) =>
      (catalog[key] as List<dynamic>).cast<Map<String, dynamic>>();

  /// Simula la latencia de red para que se vean los skeletons.
  Future<void> delay() => Future<void>.delayed(latency);

  Map<String, Object?> money(int cents, [String currency = 'PEN']) => {
    'amount': cents,
    'currency': currency,
  };
}
