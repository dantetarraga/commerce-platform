// Local visual review: flutter run -d chrome -t tool/onboarding_preview.dart
// Add ?theme=dark before #/onboarding to preview the dark palette.
// Reloading resets only these in-memory preview preferences.
import 'package:apamuy/app/router/app_router.dart';
import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/config/env.dart';
import 'package:apamuy/core/storage/preferences_storage.dart';
import 'package:apamuy/core/storage/storage_providers.dart';
import 'package:apamuy/shared/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(
  ProviderScope(
    retry: (_, _) => null,
    overrides: [
      preferencesStorageProvider.overrideWithValue(_PreviewPreferences()),
      appEnvProvider.overrideWithValue(
        const AppEnv(
          apiBaseUrl: 'http://localhost:3000/api/v1',
          useFakeData: true,
        ),
      ),
    ],
    child: const _Preview(),
  ),
);

class _PreviewPreferences extends PreferencesStorage {
  bool _seen = false;

  @override
  Future<bool> isOnboardingSeen() async => _seen;

  @override
  Future<void> markOnboardingSeen() async => _seen = true;
}

class _Preview extends ConsumerWidget {
  const _Preview();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Apamuy · Onboarding',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: Uri.base.queryParameters['theme'] == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light,
    routerConfig: ref.watch(appRouterProvider),
    locale: const Locale('es', 'PE'),
    supportedLocales: const [Locale('es', 'PE'), Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
  );
}
