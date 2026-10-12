import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu_import.dart';
import 'package:apamuy/features/orders/orders_infrastructure.dart';

/// Mapeo JSON ↔ entidades de `merchant/catalog/*` (el mismo JSON que edita el panel web).
abstract final class MenuJson {
  static List<Map<String, dynamic>> _rows(Object? json) => (json as List? ?? const []).cast<Map<String, dynamic>>();

  static StoreMenu menu(Map<String, dynamic> json) => StoreMenu(
    storeId: json['id'] as String,
    storeName: json['name'] as String,
    currency: (json['minOrderAmount'] as Map?)?['currency'] as String? ?? 'PEN',
    sections: [
      for (final s in _rows(json['sections'])) MenuSection(id: s['id'] as String, name: s['name'] as String),
    ],
    products: [for (final p in _rows(json['products'])) product(p)],
  );

  static MenuProduct product(Map<String, dynamic> json) => MenuProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    price: OrderJson.moneyFromJson(json['basePrice']),
    sectionId: json['menuSectionId'] as String?,
    stock: json['stock'] as int?,
    isAvailable: json['isAvailable'] as bool,
    variantCount: (json['variants'] as List?)?.length ?? 0,
  );

  /// Cuerpo de `POST`/`PATCH` de un producto. Sin `variants` ni `options`: un
  /// PATCH con listas vacías borraría las que ya tiene.
  static Map<String, Object?> draft(ProductDraft draft, {required String currency}) => {
    'name': draft.name,
    'description': draft.description,
    'imageUrl': draft.imageUrl,
    'menuSectionId': draft.sectionId,
    'stock': draft.stock,
    'isAvailable': draft.isAvailable,
    if (draft.price case final price?) 'basePrice': {'amount': price.cents, 'currency': currency},
  };

  static Money? _money(Object? json) => json == null ? null : OrderJson.moneyFromJson(json);

  static ImportResult importResult(Map<String, dynamic> json) => ImportResult(
    dryRun: json['dryRun'] as bool,
    created: json['created'] as int,
    updated: json['updated'] as int,
    unchanged: json['unchanged'] as int,
    failed: json['failed'] as int,
    sectionsCreated: (json['sectionsCreated'] as List? ?? const []).cast<String>(),
    rows: [
      for (final r in _rows(json['rows']))
        ImportRowResult(
          line: r['line'] as int,
          name: r['name'] as String? ?? '',
          action: ImportAction.values.asNameMap()[r['action']] ?? ImportAction.error,
          errors: (r['errors'] as List? ?? const []).cast<String>(),
          warnings: (r['warnings'] as List? ?? const []).cast<String>(),
          changes: [
            for (final c in (r['changes'] as List? ?? const []).cast<String>()) ?ImportChange.values.asNameMap()[c],
          ],
          priceFrom: _money((r['price'] as Map?)?['from']),
          priceTo: _money((r['price'] as Map?)?['to']),
        ),
    ],
  );
}
