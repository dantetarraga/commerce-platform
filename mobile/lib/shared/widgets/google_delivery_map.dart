import 'dart:async';
import 'dart:ui' as ui;

import 'package:apamuy/core/maps/delivery_map_data.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/widgets/delivery_map.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Seguimiento sobre Google Maps: el negocio, tu puerta y, mientras va en
/// camino, la moto. Sin coordenadas cae al recorrido ilustrado.
class GoogleDeliveryMapAdapter implements DeliveryMapAdapter {
  const GoogleDeliveryMapAdapter();

  @override
  Widget build(BuildContext context, DeliveryMapData data) {
    final store = data.store;
    final destination = data.destination;
    if (store == null || destination == null) return const IllustratedDeliveryMapAdapter().build(context, data);
    return _GoogleDeliveryMap(data: data, store: store, destination: destination);
  }
}

class _GoogleDeliveryMap extends StatefulWidget {
  const _GoogleDeliveryMap({required this.data, required this.store, required this.destination});

  final DeliveryMapData data;
  final MapCoordinate store;
  final MapCoordinate destination;

  @override
  State<_GoogleDeliveryMap> createState() => _GoogleDeliveryMapState();
}

class _GoogleDeliveryMapState extends State<_GoogleDeliveryMap> {
  // Sin negocios ni transporte: solo calles, para que resalten los tres puntos.
  static const _style = '''
[
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]}
]''';

  GoogleMapController? _controller;
  _MarkerIcons? _icons;
  var _framedCourier = false;

  static LatLng _latLng(MapCoordinate c) => LatLng(c.latitude, c.longitude);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_icons != null) return;
    unawaited(
      _MarkerIcons.load(MediaQuery.devicePixelRatioOf(context)).then((icons) {
        if (mounted) setState(() => _icons = icons);
      }),
    );
  }

  @override
  void didUpdateWidget(_GoogleDeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cuando aparece la moto, se encuadra una vez para que entre; después la
    // cámara queda donde la deje el cliente.
    if (widget.data.courier != null && !_framedCourier) unawaited(_frame());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _frame() async {
    final controller = _controller;
    if (controller == null) return;
    final points = [widget.store, widget.destination, ?widget.data.courier];
    _framedCourier = widget.data.courier != null;
    final south = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final north = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final west = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final east = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    // Negocio y puerta casi en el mismo punto: un zoom de calle.
    if ((north - south).abs() < 0.0005 && (east - west).abs() < 0.0005) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(_latLng(widget.destination), 17));
      return;
    }
    final bounds = LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east));
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 56));
  }

  Set<Marker> _markers(_MarkerIcons icons, LatLng? courier) => {
    Marker(
      markerId: const MarkerId('store'),
      position: _latLng(widget.store),
      icon: icons.store,
      anchor: _MarkerIcons.cornerAnchor,
      infoWindow: InfoWindow(title: widget.data.storeLabel),
    ),
    Marker(
      markerId: const MarkerId('destination'),
      position: _latLng(widget.destination),
      icon: icons.door,
      anchor: _MarkerIcons.cornerAnchor,
      infoWindow: InfoWindow(title: widget.data.destinationLabel),
    ),
    if (courier != null)
      Marker(
        markerId: const MarkerId('courier'),
        position: courier,
        icon: icons.courier,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 2,
      ),
  };

  @override
  Widget build(BuildContext context) {
    final icons = _icons;
    final courier = widget.data.courier;
    final top = MediaQuery.paddingOf(context).top;
    return Semantics(
      label:
          'Mapa del pedido: ${widget.data.storeLabel} y ${widget.data.destinationLabel}'
          '${courier != null ? ', con tu repartidor en camino' : ''}.',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<LatLng?>(
          // La moto se desliza entre una posición y la siguiente.
          tween: _LatLngTween(end: courier == null ? null : _latLng(courier)),
          duration: reduceMotionOf(context) ? Duration.zero : const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
          builder: (context, position, _) => GoogleMap(
            initialCameraPosition: CameraPosition(target: _latLng(widget.destination), zoom: 15),
            style: _style,
            padding: EdgeInsets.fromLTRB(24, top + 64, 24, 24),
            markers: icons == null ? const {} : _markers(icons, position),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            onMapCreated: (controller) {
              _controller = controller;
              unawaited(_frame());
            },
          ),
        ),
      ),
    );
  }
}

class _LatLngTween extends Tween<LatLng?> {
  _LatLngTween({super.end});

  @override
  LatLng? lerp(double t) {
    final from = begin;
    final to = end;
    if (from == null || to == null) return to;
    return LatLng(from.latitude + (to.latitude - from.latitude) * t, from.longitude + (to.longitude - from.longitude) * t);
  }
}

/// Íconos de los marcadores, dibujados una vez con los colores de la marca.
/// El negocio y la puerta son el cuadro con la esquina de salida: la esquina
/// corta marca el punto. La moto es un círculo.
class _MarkerIcons {
  const _MarkerIcons({required this.store, required this.door, required this.courier});

  final BitmapDescriptor store;
  final BitmapDescriptor door;
  final BitmapDescriptor courier;

  static const _size = 44.0;
  static const _border = 3.0;

  /// La esquina inferior izquierda del cuadro (no la del lienzo, que tiene borde).
  static const cornerAnchor = Offset(_border / _size, 1 - _border / _size);

  static Future<_MarkerIcons>? _cache;

  static Future<_MarkerIcons> load(double dpr) => _cache ??= () async {
    return _MarkerIcons(
      store: await _draw(Icons.storefront_rounded, fill: AppColors.blanco, ink: AppColors.tinta, dpr: dpr),
      door: await _draw(Icons.home_rounded, fill: AppColors.terracota, ink: AppColors.blanco, dpr: dpr),
      courier: await _draw(Icons.moped_rounded, fill: AppColors.terracota, ink: AppColors.blanco, dpr: dpr, round: true),
    );
  }();

  static Future<BitmapDescriptor> _draw(
    IconData icon, {
    required Color fill,
    required Color ink,
    required double dpr,
    bool round = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    const rect = Rect.fromLTWH(_border, _border, _size - _border * 2, _size - _border * 2);
    final shape = round
        ? RRect.fromRectAndRadius(rect, const Radius.circular(_size))
        : RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(13),
            topRight: const Radius.circular(13),
            bottomRight: const Radius.circular(13),
            bottomLeft: const Radius.circular(2),
          );
    canvas
      ..drawRRect(shape.inflate(_border), Paint()..color = round ? AppColors.blanco : AppColors.terracota700)
      ..drawRRect(shape, Paint()..color = fill);
    final glyph = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 22, color: ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(canvas, Offset((_size - glyph.width) / 2, (_size - glyph.height) / 2));
    final image = await recorder.endRecording().toImage((_size * dpr).ceil(), (_size * dpr).ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: dpr);
  }
}
