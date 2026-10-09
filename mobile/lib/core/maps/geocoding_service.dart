import 'dart:io';

import 'package:apamuy/core/config/city.dart';
import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geocoding_service.g.dart';

/// Coordenadas ↔ calle. Solo sugiere: el pin manda sobre el texto.
abstract interface class GeocodingService {
  /// La calle (y número, si lo hay) en [point], o `null` si no se sabe.
  Future<String?> streetAt(GeoCoordinates point);

  /// Dónde queda [street] dentro de la zona de reparto, o `null`.
  /// El primer resultado que cumple [within] (la zona de reparto).
  Future<GeoCoordinates?> find(String street, {required bool Function(GeoCoordinates) within});
}

/// El geocodificador del sistema (en Android, el de Google): sin key ni costo.
final class PlatformGeocodingService implements GeocodingService {
  PlatformGeocodingService();

  final _geocoding = Geocoding(locale: const Locale('es', 'PE'));

  // "8GQ2+X3" (plus code) o "Unnamed Road" no sirven como dirección.
  static final _useless = RegExp(r'^[23456789CFGHJMPQRVWX]{4,8}\+|unnamed|sin nombre', caseSensitive: false);

  @override
  Future<String?> streetAt(GeoCoordinates point) async {
    try {
      final places = await _geocoding.placemarkFromCoordinates(point.latitude, point.longitude);
      for (final place in places) {
        final street = [place.thoroughfare, place.subThoroughfare].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
        final candidate = street.isNotEmpty ? street : (place.street ?? '');
        if (candidate.trim().isNotEmpty && !_useless.hasMatch(candidate)) return candidate.trim();
      }
    } on Object {
      // Sin red o sin resultado: el usuario la escribe.
    }
    return null;
  }

  @override
  Future<GeoCoordinates?> find(String street, {required bool Function(GeoCoordinates) within}) async {
    try {
      final found = await _geocoding.locationFromAddress('$street, $cityName, Espinar, Cusco, Perú');
      for (final location in found) {
        final point = GeoCoordinates.trusted(location.latitude, location.longitude);
        if (within(point)) return point;
      }
    } on Object {
      // Igual que arriba: se mueve el mapa a mano.
    }
    return null;
  }
}

/// Sin geocodificador (tests, web, escritorio).
final class NoGeocodingService implements GeocodingService {
  const NoGeocodingService();

  @override
  Future<String?> streetAt(GeoCoordinates point) async => null;

  @override
  Future<GeoCoordinates?> find(String street, {required bool Function(GeoCoordinates) within}) async => null;
}

@Riverpod(keepAlive: true)
GeocodingService geocodingService(Ref ref) =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS) ? PlatformGeocodingService() : const NoGeocodingService();
