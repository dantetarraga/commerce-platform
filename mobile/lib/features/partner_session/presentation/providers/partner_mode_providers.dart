import 'package:chaski/core/storage/storage_providers.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/partner_session/domain/partner_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_mode_providers.g.dart';

/// Modo que el socio eligió la última vez, guardado en el dispositivo.
@Riverpod(keepAlive: true)
class PartnerModePreference extends _$PartnerModePreference {
  static const _key = 'chaski.partnerMode';

  @override
  PartnerMode? build() {
    ref.read(localJsonStoreProvider).read(_key).then((value) {
      final saved = PartnerMode.values.where((m) => m.name == value).firstOrNull;
      if (saved != null && ref.mounted) state = saved;
    }).ignore();
    return null;
  }

  Future<void> set(PartnerMode mode) async {
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
