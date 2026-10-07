import 'package:chaski/core/fake/fake_backend.dart';

/// Proyecciones del catálogo de prueba al JSON que devolverá la API.
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
    'nextOpeningAt': _nextOpeningAt(store, DateTime.now()),
  };

  /// Como el backend: si el negocio está cerrado, la próxima apertura según
  /// su horario (ISO 8601 en UTC); `null` si está abierto o no abre en la semana.
  String? _nextOpeningAt(Map<String, dynamic> store, DateTime now) {
    if (store['isOpenNow'] == true) return null;
    final schedules = (store['schedules'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    final minutes = now.hour * 60 + now.minute;
    for (var offset = 0; offset <= 7; offset++) {
      final day = (now.weekday + offset) % 7;
      final opens = [
        for (final h in schedules)
          if (h['dayOfWeek'] == day && (offset > 0 || (h['opensAt'] as int) > minutes)) h['opensAt'] as int,
      ]..sort();
      if (opens.isNotEmpty) {
        return DateTime(now.year, now.month, now.day + offset, opens.first ~/ 60, opens.first % 60).toUtc().toIso8601String();
      }
    }
    return null;
  }

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
