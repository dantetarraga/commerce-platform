import 'dart:async';
import 'dart:io';

import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_service.g.dart';

/// Resultado de pedirle la ubicación al teléfono.
sealed class LocationReading {
  const LocationReading();
}

final class LocationFix extends LocationReading {
  const LocationFix(this.coordinates);

  final GeoCoordinates coordinates;
}

/// El GPS del teléfono está apagado.
final class LocationOff extends LocationReading {
  const LocationOff();
}

/// Sin permiso. Con [forever] solo se puede dar desde los ajustes.
final class LocationDenied extends LocationReading {
  const LocationDenied({this.forever = false});

  final bool forever;
}

/// No hubo señal a tiempo o la plataforma no tiene GPS.
final class LocationUnavailable extends LocationReading {
  const LocationUnavailable();
}

abstract interface class LocationService {
  /// Con [ask] en `false` no muestra el diálogo de permiso: solo lee si ya lo hay.
  Future<LocationReading> current({bool ask = true});

  /// Abre los ajustes que corresponden a [reading] (GPS o permisos de la app).
  Future<void> openSettings(LocationReading reading);
}

final class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  static const _timeout = Duration(seconds: 10);

  @override
  Future<LocationReading> current({bool ask = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return const LocationOff();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && ask) permission = await Geolocator.requestPermission();
      switch (permission) {
        case LocationPermission.deniedForever:
          return const LocationDenied(forever: true);
        case LocationPermission.denied || LocationPermission.unableToDetermine:
          return const LocationDenied();
        case LocationPermission.whileInUse || LocationPermission.always:
          break;
      }
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: _timeout));
      } on TimeoutException {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) return const LocationUnavailable();
      return LocationFix(GeoCoordinates.trusted(position.latitude, position.longitude));
    } on Object {
      return const LocationUnavailable();
    }
  }

  @override
  Future<void> openSettings(LocationReading reading) async {
    if (reading is LocationOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}

/// Sin GPS (tests, web, escritorio).
final class NoLocationService implements LocationService {
  const NoLocationService();

  @override
  Future<LocationReading> current({bool ask = true}) async => const LocationUnavailable();

  @override
  Future<void> openSettings(LocationReading reading) async {}
}

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS) ? const GeolocatorLocationService() : const NoLocationService();

/// Por ahora el mapa de Google solo está configurado en Android (falta la key de iOS).
/// En los tests `Platform.isAndroid` es falso y se usa el plano dibujado.
final bool googleMapsSupported = !kIsWeb && Platform.isAndroid;
