import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Acciones de los socios con un solo patrón: marca [busy], espera, revisa que la
/// pantalla siga montada y avisa con un toast (el error, o el texto de éxito).
mixin PartnerActionRunner<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  var _busy = false;

  /// Hay una acción en curso: deshabilita los botones mientras tanto.
  bool get busy => _busy;

  /// Corre [action] (devuelve `null` si salió bien). Ignora el toque si ya hay
  /// otra en curso. Devuelve `true` si salió bien.
  Future<bool> run(Future<Failure?> Function() action, {String? success}) async {
    if (_busy) return false;
    setState(() => _busy = true);
    final failure = await action();
    if (!mounted) return failure == null;
    setState(() => _busy = false);
    if (failure != null) {
      AppToast.show(context, failure.message, kind: AppToastKind.error);
    } else if (success != null) {
      AppToast.show(context, success, kind: AppToastKind.success);
    }
    return failure == null;
  }
}
