import 'dart:async';

import 'package:apamuy/core/push/push_providers.dart';
import 'package:apamuy/features/auth/auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mantiene registrado el teléfono para push mientras hay sesión y entrega a [onOpened]
/// los datos de cada aviso que el usuario toca (también el que abrió la app).
class PushOpenedListener extends ConsumerStatefulWidget {
  const PushOpenedListener({required this.onOpened, required this.child, this.onResumed, super.key});

  final void Function(Map<String, String> data) onOpened;

  /// La app volvió al frente (por el ícono, sin tocar el aviso).
  final VoidCallback? onResumed;
  final Widget child;

  @override
  ConsumerState<PushOpenedListener> createState() => _PushOpenedListenerState();
}

class _PushOpenedListenerState extends ConsumerState<PushOpenedListener> {
  StreamSubscription<Map<String, String>>? _opened;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _opened = ref.read(pushMessagingProvider).onOpened.listen((data) => widget.onOpened(data));
    _lifecycle = AppLifecycleListener(onResume: () => widget.onResumed?.call());
    widget.onResumed?.call();
  }

  @override
  void dispose() {
    unawaited(_opened?.cancel());
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(pushRegistrationProvider);
    return widget.child;
  }
}
