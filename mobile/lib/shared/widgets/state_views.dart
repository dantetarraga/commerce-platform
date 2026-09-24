import 'package:chaski/shared/design_system/components/app_empty_state.dart';
import 'package:flutter/material.dart';

/// Estado de error: delega en [AppEmptyState] (hilo cortado / enredado).
class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, this.onRetry, this.compact = false, super.key});

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) => AppEmptyState.fromError(error, onRetry: onRetry, compact: compact);
}

/// Estado vacío: delega en [AppEmptyState].
class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  });

  final String title;
  final String message;

  /// Se conserva por compatibilidad; la escena de hilo reemplaza al ícono.
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    title: title,
    message: message,
    kind: icon == Icons.search_off_rounded ? AppEmptyKind.noResults : AppEmptyKind.empty,
    actionLabel: actionLabel,
    onAction: onAction,
    compact: compact,
  );
}
