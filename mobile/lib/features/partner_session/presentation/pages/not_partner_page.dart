import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/utils/external_links.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Se muestra cuando alguien entra a Chaski Socios sin ser socio: con sesión
/// de cliente o con un celular que no tiene cuenta. Chaski Socios no crea
/// cuentas: al socio lo da de alta el equipo (ver docs/OPERACION.md).
class NotPartnerPage extends ConsumerWidget {
  const NotPartnerPage({required this.onUseAnotherNumber, super.key});

  static const name = 'notPartner';

  /// Vuelve a la entrada (después de cerrar la sesión, si había).
  final VoidCallback onUseAnotherNumber;

  Future<void> _anotherNumber(WidgetRef ref) async {
    ref.read(phoneAuthFlowProvider.notifier).reset();
    if (ref.read(authSessionProvider).value != null) {
      await ref.read(authSessionProvider.notifier).logout();
    }
    onUseAnotherNumber();
  }

  Future<void> _contact(BuildContext context, String phone) async {
    final opened = await ExternalLinks.whatsapp(phone, text: 'Hola, quiero ser socio de $brandName.');
    if (!opened && context.mounted) AppToast.show(context, 'No pudimos abrir WhatsApp.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = ref.watch(appEnvProvider).supportWhatsapp;
    return AuthScaffold(
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (support.isNotEmpty) ...[
            AppButton(label: 'Escríbenos por WhatsApp', onPressed: () => _contact(context, support)),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppButton.secondary(label: 'Usar otro número', onPressed: () => _anotherNumber(ref)),
        ],
      ),
      children: const [
        AuthHeader(
          title: 'Aún no eres socio de $brandName',
          subtitle: Text(
            '$brandName Socios es para negocios y repartidores afiliados. '
            'Si quieres vender o repartir con nosotros, escríbenos y te damos de alta.',
          ),
        ),
      ],
    );
  }
}
