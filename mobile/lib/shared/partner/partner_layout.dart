import 'package:chaski/core/utils/text_scale.dart';
import 'package:flutter/widgets.dart';

/// Puntos de quiebre de Apamuy Socios (tablet en el mostrador vs. celular).
abstract final class PartnerLayout {
  /// Ancho desde el que el riel muestra sus tres columnas lado a lado.
  static const wideBoard = 900.0;

  /// Ancho desde el que las listas de comandas van en dos columnas.
  static const twoColumns = 800.0;

  /// Ancho mínimo para poner dos botones lado a lado.
  static const sideBySide = 280.0;

  /// `true` si hay ancho para [minWidth] y la letra del sistema no es grande
  /// (con letra grande todo va en una columna). Por defecto mide la pantalla;
  /// con [width] mide el espacio dado (p. ej. de un `LayoutBuilder`).
  static bool isWide(BuildContext context, {double minWidth = wideBoard, double? width}) =>
      (width ?? MediaQuery.sizeOf(context).width) >= minWidth && !isLargeText(context, base: 14);

  /// Columnas para una lista de comandas en [width] px: 2 o 1.
  static int columnsFor(BuildContext context, double width) => isWide(context, minWidth: twoColumns, width: width) ? 2 : 1;
}
