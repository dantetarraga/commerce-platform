import 'package:apamuy/core/maps/delivery_map_data.dart';
import 'package:apamuy/shared/maps/google_delivery_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const store = MapCoordinate(-14.7936, -71.4128); // Yauri
  const nearDoor = MapCoordinate(-14.7958, -71.4101);
  const farDoor = MapCoordinate(-13.5319, -71.9675); // Cusco
  const rider = MapCoordinate(-14.70, -71.50);

  MapCoordinate? focus(MapCoordinate door, {double progress = 0, MapCoordinate? courier}) =>
      farFocus(DeliveryMapData(estimatedProgress: progress, courier: courier), store: store, destination: door);

  test('cerca: se encuadran el negocio y la puerta', () {
    expect(focus(nearDoor), isNull);
  });

  test('lejos: la calle del negocio, de la moto o de la puerta según el momento', () {
    expect(focus(farDoor), same(store));
    expect(focus(farDoor, courier: rider), same(rider));
    expect(focus(farDoor, progress: 0.9), same(farDoor));
  });
}
