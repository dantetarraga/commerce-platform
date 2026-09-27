// Genera la ilustración vectorial propia de Chaski; no necesita el editor Rive.
// Formato público: rive-app/rive-runtime/include/rive/runtime_header.hpp y
// include/rive/generated/{shapes,animation}/*_base.hpp (formato 7.0).
// El test rive_success_test.dart verifica este archivo con el runtime real.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final scene = _RiveScene()
    ..object(23, {}) // Backboard.
    ..object(1, {4: 'ChaskiSuccess', 7: 240.0, 8: 240.0});
  // Los índices de componentes empiezan en el artboard (0).
  final badge = scene.component(2, {4: 'Badge', 5: 0, 13: 120.0, 14: 120.0});
  final check = scene.polygon('Check', badge, 0, 0, const [
    (-35.0, 0.0),
    (-25.0, -10.0),
    (-9.0, 6.0),
    (26.0, -29.0),
    (36.0, -19.0),
    (-9.0, 26.0),
  ], 0xFFFFFFFF);
  // Rive apila las formas de delante hacia atrás.
  scene.circle('Cobalto', badge, 0, 0, 120, 0xFF1D5BFF);
  final halo = scene.circle('Halo', 0, 120, 120, 172, 0x201D5BFF);
  final sparks = <({int id, double x, double y})>[];
  for (var i = 0; i < 6; i++) {
    final angle = (i * 60 - 20) * math.pi / 180;
    final x = 120 + 96 * math.cos(angle);
    final y = 120 + 96 * math.sin(angle);
    final id = scene.polygon('Spark$i', 0, x, y, const [
      (0.0, -7.0),
      (3.0, -2.0),
      (7.0, 0.0),
      (3.0, 2.0),
      (0.0, 7.0),
      (-3.0, 2.0),
      (-7.0, 0.0),
      (-3.0, -2.0),
    ], i.isEven ? 0xFFC5F25A : 0xFF7C9DFF);
    sparks.add((id: id, x: x, y: y));
  }
  // Una sola reproducción, 72 fotogramas a 60 fps (1,2 s).
  scene.object(31, {55: 'confirm', 56: 60, 57: 72, 59: 0});
  for (final property in [16, 17]) {
    scene
      ..animate(badge, property, [(0, 0.12), (12, 0.85), (20, 1.08), (30, 0.98), (38, 1.0), (72, 1.0)])
      ..animate(halo, property, [(0, 0.5), (20, 0.85), (44, 1.05), (60, 1.0), (72, 1.0)])
      ..animate(check, property, [(0, 0.0), (12, 0.0), (24, 1.12), (34, 1.0), (72, 1.0)]);
  }
  scene.animate(badge, 18, [(0, 0.0), (6, 1.0), (72, 1.0)]);
  for (final spark in sparks) {
    scene
      ..animate(spark.id, 18, [(0, 0.0), (12, 0.0), (24, 1.0), (48, 1.0), (72, 0.0)])
      ..animate(spark.id, 13, [(0, 120 + (spark.x - 120) * 0.6), (48, spark.x), (72, spark.x)])
      ..animate(spark.id, 14, [(0, 120 + (spark.y - 120) * 0.6), (48, spark.y), (72, spark.y + 6)]);
  }
  final file = File('assets/animations/chaski_success.riv');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(scene.bytes.takeBytes());
  stdout.writeln('${file.path}: ${file.lengthSync()} bytes');
}

class _RiveScene {
  _RiveScene() {
    bytes.add([82, 73, 86, 69, 7, 0, 0, 0]); // RIVE, v7.0, id 0, TOC vacío.
  }

  final bytes = BytesBuilder();
  var _componentId = 0;

  void uint(int value) {
    var remaining = value;
    while (remaining >= 128) {
      bytes.addByte((remaining & 127) | 128);
      remaining >>= 7;
    }
    bytes.addByte(remaining);
  }

  void object(int type, Map<int, Object> fields) {
    uint(type);
    for (final entry in fields.entries) {
      uint(entry.key);
      final value = entry.value;
      if (entry.key == 37) {
        bytes.add((ByteData(4)..setUint32(0, value as int, Endian.little)).buffer.asUint8List());
      } else if (value is double) {
        bytes.add((ByteData(4)..setFloat32(0, value, Endian.little)).buffer.asUint8List());
      } else if (value is String) {
        // Los nombres del asset son ASCII.
        uint(value.length);
        bytes.add(value.codeUnits);
      } else {
        uint(value as int);
      }
    }
    uint(0);
  }

  int component(int type, Map<int, Object> fields) {
    object(type, fields);
    return ++_componentId;
  }

  void fill(int shape, int color) {
    final fillId = component(20, {5: shape});
    component(18, {5: fillId, 37: color});
  }

  int circle(String name, int parent, double x, double y, double size, int color) {
    final shape = component(3, {4: name, 5: parent, 13: x, 14: y});
    component(4, {5: shape, 20: size, 21: size});
    fill(shape, color);
    return shape;
  }

  int polygon(String name, int parent, double x, double y, List<(double, double)> points, int color) {
    final shape = component(3, {4: name, 5: parent, 13: x, 14: y});
    final path = component(16, {5: shape, 32: 1});
    for (final (x, y) in points) {
      component(5, {5: path, 24: x, 25: y, 26: 2.0});
    }
    fill(shape, color);
    return shape;
  }

  void animate(int componentId, int property, List<(int, double)> frames) {
    object(25, {51: componentId});
    object(26, {53: property});
    for (final (frame, value) in frames) {
      object(30, {67: frame, 68: 1, 70: value}); // Interpolación lineal.
    }
  }
}
