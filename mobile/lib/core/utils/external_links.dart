import 'package:url_launcher/url_launcher.dart';

/// Abre apps externas (teléfono, WhatsApp, mapas). Devuelve `false` si el
/// teléfono no pudo abrirlas, para que la pantalla avise.
abstract final class ExternalLinks {
  static Future<bool> call(String phone) => _open(Uri(scheme: 'tel', path: phone));

  /// [phone] de 9 dígitos, sin +51.
  static Future<bool> whatsapp(String phone, {String? text}) => _open(
    Uri.https('wa.me', '/51$phone', {'text': ?text}),
  );

  /// Ruta hasta ese punto en Google Maps (navegación lista para empezar).
  static Future<bool> directions(double lat, double lng) => _open(
    Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': '$lat,$lng', 'travelmode': 'driving'}),
  );

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
