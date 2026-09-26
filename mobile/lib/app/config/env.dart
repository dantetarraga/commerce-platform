/// Configuración de compilación leída con `--dart-define-from-file=env/<entorno>.json`.
final class AppEnv {
  const AppEnv({required this.apiBaseUrl, required this.useFakeData, this.supportWhatsapp = ''});

  factory AppEnv.fromEnvironment() => const AppEnv(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000/api/v1',
    ),
    useFakeData: bool.fromEnvironment('USE_FAKE_DATA', defaultValue: true),
    // El analizador ve '' en tiempo de análisis; en compilación sale del env.
    // ignore: avoid_redundant_argument_values
    supportWhatsapp: String.fromEnvironment('SUPPORT_WHATSAPP'),
  );

  final String apiBaseUrl;
  final bool useFakeData;

  /// Celular de soporte (9 dígitos, sin +51). Vacío: no se ofrece WhatsApp.
  final String supportWhatsapp;
}
