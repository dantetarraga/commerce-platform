import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Igual que tu teléfono',
  ThemeMode.light => 'Claro',
  ThemeMode.dark => 'Oscuro',
};

/// Hoja "Tema". Devuelve el modo elegido o null si se cierra sin elegir.
Future<ThemeMode?> showThemeModeSheet(BuildContext context, {required ThemeMode current}) => showAppBottomSheet<ThemeMode>(
  context,
  title: 'Tema',
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      RadioGroup<ThemeMode>(
        groupValue: current,
        onChanged: (mode) => Navigator.of(context).pop(mode),
        child: Column(
          children: [
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(value: mode, title: Text(themeModeLabel(mode)), contentPadding: AppSpacing.screen),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
    ],
  ),
);
