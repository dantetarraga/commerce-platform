import 'package:apamuy/core/storage/storage_providers.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// Tema elegido por el usuario, guardado en el dispositivo.
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  static const _key = 'apamuy.themeMode';

  @override
  ThemeMode build() {
    ref.read(localJsonStoreProvider).read(_key).then((value) {
      final saved = ThemeMode.values.where((m) => m.name == value).firstOrNull;
      if (saved != null && ref.mounted) state = saved;
    }).ignore();
    return ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(localJsonStoreProvider).write(_key, mode.name);
  }
}
