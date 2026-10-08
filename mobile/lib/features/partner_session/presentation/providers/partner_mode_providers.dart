import 'package:apamuy/core/storage/storage_providers.dart';
import 'package:apamuy/features/auth/auth.dart';
import 'package:apamuy/features/partner_session/domain/partner_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_mode_providers.g.dart';

/// Modo que el socio eligió la última vez, guardado en el dispositivo.
@Riverpod(keepAlive: true)
class PartnerModePreference extends _$PartnerModePreference {
  static const _key = 'apamuy.partnerMode';

  /// Ya eligió en esta sesión: lo guardado (que llega después) no lo pisa.
  var _chosen = false;

  @override
  PartnerMode? build() {
    ref.read(localJsonStoreProvider).read(_key).then((value) {
      final saved = PartnerMode.values.where((m) => m.name == value).firstOrNull;
      // Solo avisa (y redirige) si lo guardado cambia algo.
      if (saved != null && !_chosen && ref.mounted && state != saved) state = saved;
    }).ignore();
    return null;
  }

  Future<void> set(PartnerMode mode) async {
    _chosen = true;
    state = mode;
    await ref.read(localJsonStoreProvider).write(_key, mode.name);
  }
}

/// Modos a los que puede entrar el usuario con sesión.
@riverpod
List<PartnerMode> availablePartnerModesFor(Ref ref) {
  final user = ref.watch(authSessionProvider).value;
  if (user == null) return const [];
  return availablePartnerModes(isMerchant: user.isMerchant, isCourier: user.isCourier);
}

/// Modo activo: el elegido si sigue siendo válido, o el primero disponible.
@riverpod
PartnerMode? activePartnerMode(Ref ref) =>
    resolvePartnerMode(ref.watch(availablePartnerModesForProvider), ref.watch(partnerModePreferenceProvider));
