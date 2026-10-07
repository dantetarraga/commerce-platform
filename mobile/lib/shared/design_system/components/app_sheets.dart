import 'package:chaski/shared/design_system/components/app_button.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppSheetSize {
  /// Se ajusta al contenido.
  fit,

  /// Media pantalla, arrastrable hasta completa.
  half,

  /// Casi completa (carrito largo, dirección con mapa).
  full,
}

/// Abre una hoja inferior de Apamuy (radio 24 arriba, asa visible).
/// Carrito, selector de dirección y filtros son hojas: no sacan al usuario de
/// contexto. Con [title] (y opcionalmente [subtitle]) arma un [AppSheetHeader].
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  AppSheetSize size = AppSheetSize.fit,
  String? title,
  String? subtitle,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) AppSheetHeader(title: title, subtitle: subtitle),
          Flexible(child: builder(context)),
        ],
      );
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      return switch (size) {
        AppSheetSize.fit => Padding(padding: EdgeInsets.only(bottom: bottomInset), child: content),
        AppSheetSize.half || AppSheetSize.full => Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * (size == AppSheetSize.half ? 0.55 : 0.9),
            child: content,
          ),
        ),
      };
    },
  );
}

/// Cabecera de una hoja inferior: título (encabezado) y una bajada opcional
/// en `bodyMedium` atenuado. Úsala en hojas que arman su propio contenido;
/// `showAppBottomSheet(title:, subtitle:)` ya la incluye.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({required this.title, this.subtitle, this.padding = defaultPadding, super.key});

  static const defaultPadding = EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm);

  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(header: true, child: Text(title, style: theme.textTheme.headlineSmall)),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// Diálogo de confirmación. Solo para decisiones con consecuencias (vaciar la
/// bolsa, cerrar sesión, cancelar un pedido). Devuelve `true` si confirma.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (destructive)
              AppButton.danger(label: confirmLabel, size: AppButtonSize.md, onPressed: () => Navigator.pop(context, true))
            else
              AppButton(label: confirmLabel, size: AppButtonSize.md, onPressed: () => Navigator.pop(context, true)),
            const SizedBox(height: AppSpacing.xs),
            AppButton.ghost(label: cancelLabel, expand: true, onPressed: () => Navigator.pop(context, false)),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}
