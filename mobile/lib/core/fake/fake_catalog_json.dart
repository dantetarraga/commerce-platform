import 'package:chaski/core/fake/fake_backend.dart';

/// Proyecciones del catálogo de prueba al JSON que devolverá la API.
/// Compartidas por los datasources fake de stores, products, search y promotions.
extension FakeCatalogJson on FakeBackend {
  Map<String, Object?> storeSummaryJson(Map<String, dynamic> store) => {
    'id': store['id'],
    'name': store['name'],
    'logoUrl': store['logoUrl'],
    'coverUrl': store['coverUrl'],
    'categoryIds': store['categoryIds'],
    'ratingAvg': store['ratingAvg'],
    'ratingCount': store['ratingCount'],
    'distanceKm': store['distanceKm'],
    'etaMinutes': store['etaMinutes'],
    'estimatedDeliveryFee': money(store['deliveryFee'] as int),
    'minOrderAmount': money(store['minOrderAmount'] as int),
    'isOpenNow': store['isOpenNow'],
    'deliversToYou': store['deliversToYou'],
    'tags': store['tags'] ?? <String>[],
    'promoLabel': store['promoLabel'],
  };

  Map<String, Object?> menuItemJson(Map<String, dynamic> product) {
    final variants = (product['variants'] as List<dynamic>).cast<Map<String, dynamic>>();
    final options = product['options'] as List<dynamic>;
    final availableVariantPrices = variants
        .where((v) => v['isAvailable'] == true)
        .map((v) => v['price'] as int);
    final price = availableVariantPrices.isEmpty
        ? product['basePrice'] as int
        : availableVariantPrices.reduce((a, b) => a < b ? a : b);
    return {
      'id': product['id'],
      'name': product['name'],
      'description': product['description'],
      'imageUrl': product['imageUrl'],
      'price': money(price),
      'isAvailable': product['isAvailable'],
      'hasChoices': variants.isNotEmpty || options.isNotEmpty,
      'isFeatured': product['isFeatured'] ?? false,
    };
  }

  Map<String, dynamic>? findById(List<Map<String, dynamic>> items, String id) =>
      items.where((item) => item['id'] == id).firstOrNull;
}
