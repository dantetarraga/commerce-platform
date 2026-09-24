/// Configuración de compilación leída con `--dart-define-from-file=env/<entorno>.json`.
final class AppEnv {
  const AppEnv({required this.apiBaseUrl, required this.useFakeData});

  factory AppEnv.fromEnvironment() => const AppEnv(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000/api/v1',
    ),
    useFakeData: bool.fromEnvironment('USE_FAKE_DATA', defaultValue: true),
  );

  final String apiBaseUrl;
  final bool useFakeData;
}
