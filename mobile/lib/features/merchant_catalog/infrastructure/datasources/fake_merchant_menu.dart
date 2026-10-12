import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/errors/app_exception.dart';
import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/core/utils/text_utils.dart';

/// Backend fake de la carta editable: cambia el catálogo en memoria de
/// [FakeBackend], así la lista de productos de Socios ve los cambios. Responde
/// con el JSON de `merchant/catalog/*`.
class FakeMerchantMenu {
  FakeMerchantMenu(this._backend);

  final FakeBackend _backend;
  var _nextId = 0;

  String _id(String prefix) => '${prefix}_demo_${_nextId++}';

  static Never _notFound(String message) => throw ApiException(statusCode: 404, code: 'NOT_FOUND', message: message);

  Future<(Map<String, dynamic>, List<Map<String, dynamic>>)> _catalog() async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    return (catalog, _backend.listOf(catalog, 'products'));
  }

  Map<String, dynamic> _store(Map<String, dynamic> catalog, String storeId) =>
      _backend.listOf(catalog, 'stores').where((s) => s['id'] == storeId).firstOrNull ??
      _notFound('No encontramos ese negocio.');

  List<Map<String, dynamic>> _sections(Map<String, dynamic> store) =>
      (store['menuSections'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> _product(List<Map<String, dynamic>> products, String id) =>
      products.where((p) => p['id'] == id && p['deleted'] != true).firstOrNull ??
      _notFound('No encontramos ese producto.');

  String? _sectionOf(Map<String, dynamic> store, String productId) =>
      _sections(store).where((s) => (s['productIds'] as List).contains(productId)).firstOrNull?['id'] as String?;

  void _moveTo(Map<String, dynamic> store, String productId, String? sectionId) {
    for (final s in _sections(store)) {
      final ids = (s['productIds'] as List)..remove(productId);
      if (s['id'] == sectionId) ids.add(productId);
    }
  }

  Future<Map<String, dynamic>> store(String storeId) async {
    final (catalog, products) = await _catalog();
    final store = _store(catalog, storeId);
    return {
      'id': store['id'],
      'name': store['name'],
      'minOrderAmount': _backend.money(store['minOrderAmount'] as int? ?? 0),
      'sections': [
        for (final (i, s) in _sections(store).indexed) {'id': s['id'], 'name': s['name'], 'sortOrder': i},
      ],
      'products': [
        for (final p in products)
          if (p['storeId'] == storeId && p['deleted'] != true)
            {
              'id': p['id'],
              'storeId': storeId,
              'menuSectionId': _sectionOf(store, p['id'] as String),
              'name': p['name'],
              'description': p['description'],
              'imageUrl': p['imageUrl'],
              'basePrice': _backend.money(p['basePrice'] as int),
              'isAvailable': p['isAvailable'] as bool? ?? true,
              'stock': p['stock'],
              'variants': p['variants'] ?? const <Object>[],
              'options': p['options'] ?? const <Object>[],
            },
      ],
    };
  }

  Future<void> createProduct(String storeId, Map<String, Object?> body) async {
    final (catalog, products) = await _catalog();
    final store = _store(catalog, storeId);
    final id = _id('pr');
    products.add({
      'id': id,
      'storeId': storeId,
      'name': body['name'],
      'description': body['description'],
      'imageUrl': body['imageUrl'],
      'basePrice': (body['basePrice']! as Map)['amount'],
      'isAvailable': body['isAvailable'] ?? true,
      'stock': body['stock'],
      'variants': <Object>[],
      'options': <Object>[],
    });
    _moveTo(store, id, body['menuSectionId'] as String?);
  }

  Future<void> updateProduct(String productId, Map<String, Object?> body) async {
    final (catalog, products) = await _catalog();
    final product = _product(products, productId);
    for (final key in ['name', 'description', 'imageUrl', 'isAvailable', 'stock']) {
      if (body.containsKey(key)) product[key] = body[key];
    }
    if (body['basePrice'] case final Map<String, Object?> price) product['basePrice'] = price['amount'];
    if (body.containsKey('menuSectionId')) {
      _moveTo(_store(catalog, product['storeId'] as String), productId, body['menuSectionId'] as String?);
    }
  }

  Future<void> removeProduct(String productId) async {
    final (catalog, products) = await _catalog();
    final product = _product(products, productId);
    product['deleted'] = true;
    _moveTo(_store(catalog, product['storeId'] as String), productId, null);
  }

  Future<Map<String, dynamic>> createSection(String storeId, String name) async {
    final (catalog, _) = await _catalog();
    final sections = _sections(_store(catalog, storeId));
    final section = {'id': _id('ms'), 'name': name, 'productIds': <Object>[]};
    sections.add(section);
    return {'id': section['id'], 'name': name, 'sortOrder': sections.length - 1};
  }

  Map<String, dynamic> _section(Map<String, dynamic> catalog, String sectionId) =>
      _backend.listOf(catalog, 'stores').expand(_sections).where((s) => s['id'] == sectionId).firstOrNull ??
      _notFound('No encontramos esa sección.');

  Future<void> renameSection(String sectionId, String name) async {
    final (catalog, _) = await _catalog();
    _section(catalog, sectionId)['name'] = name;
  }

  /// Sus productos quedan sin sección, como en el backend.
  Future<void> removeSection(String sectionId) async {
    final (catalog, _) = await _catalog();
    for (final store in _backend.listOf(catalog, 'stores')) {
      _sections(store).removeWhere((s) => s['id'] == sectionId);
    }
  }

  Future<void> reorderSections(String storeId, List<String> sectionIds) async {
    final (catalog, _) = await _catalog();
    final sections = _sections(_store(catalog, storeId));
    final byId = {for (final s in sections) s['id']: s};
    if (sectionIds.length != byId.length || !sectionIds.every(byId.containsKey)) {
      throw const ApiException(
        statusCode: 400,
        code: 'VALIDATION_ERROR',
        message: 'Manda todas las secciones del negocio, una vez cada una.',
      );
    }
    final ordered = [for (final id in sectionIds) byId[id]!];
    sections
      ..clear()
      ..addAll(ordered);
  }

  /// Versión corta de `catalog-import.ts`: reconoce por nombre, crea las
  /// secciones que faltan y rechaza filas sin nombre o con un precio inválido.
  Future<Map<String, dynamic>> importProducts(
    String storeId,
    List<Map<String, Object>> rows, {
    required bool dryRun,
  }) async {
    final menu = await store(storeId);
    final existing = {
      for (final p in (menu['products'] as List).cast<Map<String, dynamic>>())
        normalizeForSearch(p['name'] as String): p,
    };
    final sections = {
      for (final s in (menu['sections'] as List).cast<Map<String, dynamic>>())
        normalizeForSearch(s['name'] as String): s,
    };
    final newSections = <String, String>{};
    final results = <Map<String, Object>>[];
    final plan = <(Map<String, dynamic>?, Map<String, Object?>, String?)>[];
    for (final row in rows) {
      final name = '${row['name'] ?? ''}'.trim();
      final priceText = row['price'] as String?;
      final price = priceText == null ? null : Money.tryParse(priceText);
      final current = existing[normalizeForSearch(name)];
      final errors = [
        if (name.length < 2) 'Falta el nombre.',
        if (priceText != null && (price == null || price.isZero))
          'Precio no válido: «$priceText». Usa números como 12.50.',
        if (priceText == null && current == null && name.length >= 2) 'Falta el precio: es un producto nuevo.',
      ];
      final section = row['section'] as String?;
      if (errors.isEmpty && section != null && !sections.containsKey(normalizeForSearch(section))) {
        newSections.putIfAbsent(normalizeForSearch(section), () => section);
      }
      final before = current?['basePrice'] as Map<String, dynamic>?;
      final priceChanged = errors.isEmpty && price != null && price.cents != before?['amount'];
      results.add({
        'line': row['line']!,
        'name': name,
        'action': errors.isNotEmpty ? 'error' : (current == null ? 'create' : 'update'),
        'errors': errors,
        'warnings': <String>[],
        if (errors.isEmpty && current != null)
          'changes': [
            if (priceChanged) 'price',
            for (final field in ['description', 'stock', 'available', 'section', 'imageUrl'])
              if (row[field] != null) field,
          ],
        if (priceChanged) 'price': {'from': before, 'to': _backend.money(price.cents)},
      });
      if (errors.isEmpty) {
        plan.add((
          current,
          {
            'name': name,
            if (row['description'] != null) 'description': row['description'],
            if (price != null) 'basePrice': {'amount': price.cents},
            if (row['stock'] case final String stock) 'stock': int.tryParse(stock),
            if (row['available'] case final String available)
              'isAvailable': !normalizeForSearch(available).startsWith('n'),
            if (row['imageUrl'] != null) 'imageUrl': row['imageUrl'],
          },
          section,
        ));
      }
    }
    final summary = {
      'dryRun': dryRun,
      'created': results.where((r) => r['action'] == 'create').length,
      'updated': results.where((r) => r['action'] == 'update').length,
      'unchanged': 0,
      'failed': results.where((r) => r['action'] == 'error').length,
      'sectionsCreated': newSections.values.toList(),
      'rows': results,
    };
    if (dryRun) return summary;
    if (summary['failed'] != 0) {
      throw const ApiException(
        statusCode: 400,
        code: 'VALIDATION_ERROR',
        message: 'Hay filas con errores. Corrígelas en el archivo y vuelve a importar.',
      );
    }
    for (final name in newSections.values) {
      sections[normalizeForSearch(name)] = await createSection(storeId, name);
    }
    for (final (current, body, section) in plan) {
      final sectionId = section == null ? null : sections[normalizeForSearch(section)]?['id'] as String?;
      final withSection = {...body, 'menuSectionId': ?sectionId};
      if (current == null) {
        await createProduct(storeId, withSection);
      } else {
        await updateProduct(current['id'] as String, withSection);
      }
    }
    return summary;
  }
}
