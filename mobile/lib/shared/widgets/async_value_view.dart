import 'package:apamuy/shared/design_system/components/app_empty_state.dart';
import 'package:apamuy/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Los cuatro estados de una carga (skeleton, error con reintentar, vacío y datos),
/// con crossfade entre ellos.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    required this.loading,
    this.isEmpty,
    this.empty,
    this.onRetry,
    this.compactError = false,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget loading;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final VoidCallback? onRetry;
  final bool compactError;

  @override
  Widget build(BuildContext context) {
    final (key, child) = switch (value) {
      // Mientras recarga con datos previos, se siguen mostrando los datos.
      AsyncValue(:final value?, hasValue: true) =>
        (isEmpty?.call(value) ?? false) && empty != null ? ('empty', empty!) : ('data', data(value)),
      AsyncError(:final error) => ('error', AppEmptyState.fromError(error, onRetry: onRetry, compact: compactError)),
      _ => ('loading', loading),
    };
    return LoadCrossFade(stateKey: key, child: child);
  }
}
