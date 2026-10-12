/// Configuración de compilación leída con `--dart-define-from-file=env/<entorno>.json`.
final class AppEnv {
  const AppEnv({required this.apiBaseUrl, required this.useFakeData, this.supportWhatsapp = ''});

  factory AppEnv.fromEnvironment() => const AppEnv(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000/api/v1',
    ),
    // Sin env la app no es la demo: así un build olvidado no sale con datos falsos.
    useFakeData: bool.fromEnvironment('USE_FAKE_DATA'),
    // El analizador ve '' en tiempo de análisis; en compilación sale del env.
    // ignore: avoid_redundant_argument_values
    supportWhatsapp: String.fromEnvironment('SUPPORT_WHATSAPP'),
  );

  final String apiBaseUrl;
  final bool useFakeData;

  /// Celular de soporte (9 dígitos, sin +51). Vacío: no se ofrece WhatsApp.
  final String supportWhatsapp;

  static const _isRelease = bool.fromEnvironment('dart.vm.product');

  /// Por qué este build no debería llegar a la gente, o `null`. La demo se permite:
  /// se pide a propósito con `env/fake.json`.
  String? releaseProblem({bool release = _isRelease}) {
    if (!release || useFakeData) return null;
    if (!apiBaseUrl.startsWith('https://')) {
      return 'API_BASE_URL debe ser https en release ($apiBaseUrl). Compila con --dart-define-from-file=env/prod.json.';
    }
    return null;
  }

  /// Corta el arranque de un release mal compilado en vez de dejarlo andar a medias.
  void ensureReleaseReady() {
    if (releaseProblem() case final problem?) throw StateError(problem);
  }
}
