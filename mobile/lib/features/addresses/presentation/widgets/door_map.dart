import 'dart:async';

import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/maps/location_service.dart';
import 'package:apamuy/features/addresses/presentation/widgets/door_pin.dart';
import 'package:apamuy/features/addresses/presentation/widgets/neighborhood_plan.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Mapa que se mueve bajo un pin fijo: el punto bajo el pin es la puerta.
/// Usa Google Maps donde está configurado y, si no, el plano dibujado.
class DoorMap extends StatelessWidget {
  const DoorMap({
    required this.origin,
    required this.onCenter,
    required this.height,
    this.focus,
    this.hint,
    this.seed = '',
    super.key,
  });

  /// Dónde arranca el mapa.
  final GeoCoordinates origin;

  /// El punto bajo el pin, cada vez que el mapa se detiene.
  final ValueChanged<GeoCoordinates> onCenter;

  final double height;

  /// Al cambiar, el mapa vuela a este punto (p. ej. "Mi ubicación").
  final GeoCoordinates? focus;

  final String? hint;

  /// Calle escrita; solo la usa el plano dibujado.
  final String seed;

  /// Grados por px del plano dibujado (~1 m por px en Espinar).
  static const _degreesPerPx = 0.00001;

  @override
  Widget build(BuildContext context) {
    if (googleMapsSupported) {
      return _GoogleDoorMap(origin: origin, onCenter: onCenter, height: height, focus: focus, hint: hint);
    }
    // Arrastrar a la derecha es ir al oeste; hacia arriba, al sur.
    return NeighborhoodPlan(
      seed: seed,
      height: height,
      hint: hint,
      onMoved: (moved) => onCenter(
        GeoCoordinates.trusted(origin.latitude + moved.dy * _degreesPerPx, origin.longitude - moved.dx * _degreesPerPx),
      ),
    );
  }
}

class _GoogleDoorMap extends StatefulWidget {
  const _GoogleDoorMap({required this.origin, required this.onCenter, required this.height, this.focus, this.hint});

  final GeoCoordinates origin;
  final ValueChanged<GeoCoordinates> onCenter;
  final double height;
  final GeoCoordinates? focus;
  final String? hint;

  @override
  State<_GoogleDoorMap> createState() => _GoogleDoorMapState();
}

class _GoogleDoorMapState extends State<_GoogleDoorMap> {
  /// Se ven las casas y el nombre de las calles.
  static const _zoom = 17.5;

  // Sin negocios ni transporte: el mapa es para ubicar la puerta.
  static const _style = '''
[
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]}
]''';

  GoogleMapController? _controller;
  late LatLng _center = _latLng(widget.origin);
  var _moving = false;

  static LatLng _latLng(GeoCoordinates point) => LatLng(point.latitude, point.longitude);

  @override
  void didUpdateWidget(_GoogleDoorMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focus = widget.focus;
    if (focus != null && focus != oldWidget.focus) {
      unawaited(_controller?.animateCamera(CameraUpdate.newLatLngZoom(_latLng(focus), _zoom)));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = reduceMotionOf(context) ? Duration.zero : AppMotion.quick;
    return Semantics(
      label: 'Mapa. Muévelo para dejar tu puerta bajo el pin.',
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: _zoom),
              style: _style,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              onMapCreated: (controller) => _controller = controller,
              onCameraMoveStarted: () => setState(() => _moving = true),
              onCameraMove: (position) => _center = position.target,
              onCameraIdle: () {
                setState(() => _moving = false);
                widget.onCenter(GeoCoordinates.trusted(_center.latitude, _center.longitude));
              },
            ),
            IgnorePointer(child: Center(child: LiftingDoorPin(lifted: _moving))),
            if (widget.hint case final hint?)
              IgnorePointer(
                child: Align(
                  alignment: const Alignment(0, -0.62),
                  child: AnimatedOpacity(
                    duration: motion,
                    opacity: _moving ? 0 : 1,
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: AppRadius.tile),
                        child: Text(hint, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onInverseSurface)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
