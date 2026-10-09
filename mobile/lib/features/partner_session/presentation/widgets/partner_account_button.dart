import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/utils/external_links.dart';
import 'package:apamuy/features/auth/auth.dart';
import 'package:apamuy/features/partner_session/domain/partner_mode.dart';
import 'package:apamuy/features/partner_session/presentation/providers/partner_mode_providers.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cuenta del socio: quién entró, cambiar de modo (si tiene los dos roles) y
/// cerrar sesión.
class PartnerAccountButton extends ConsumerWidget {
  const PartnerAccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider.select((s) => s.value));
    if (user == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Tu cuenta',
      onPressed: () => showAppBottomSheet<void>(
        context,
        builder: (_) => const _AccountSheet(),
      ),
      icon: AppAvatar(
        initials: user.initials,
        imageUrl: user.avatarUrl,
        seed: user.id,
        size: 36,
      ),
    );
  }
}

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet();

  static String _label(PartnerMode mode) => switch (mode) {
    PartnerMode.merchant => 'Negocio',
    PartnerMode.courier => 'Repartidor',
  };

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '¿Cerrar sesión?',
      message: 'Dejarás de recibir pedidos en este celular hasta que vuelvas a entrar.',
      confirmLabel: 'Cerrar sesión',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    Navigator.of(context).pop();
    await ref.read(authSessionProvider.notifier).logout();
  }

  /// La cuenta de un socio la da de baja Apamuy junto con su negocio o sus repartos.
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final support = ref.read(appEnvProvider).supportWhatsapp;
    final contact = await showAppConfirmDialog(
      context,
      title: 'Eliminar tu cuenta de socio',
      message:
          'Tu cuenta está unida a tu negocio o a tus repartos, así que la damos de baja nosotros: '
          'cerramos tus pedidos pendientes y borramos tus datos personales. '
          '${support.isEmpty ? 'Escríbenos a soporte de $brandName.' : 'Escríbenos por WhatsApp y lo hacemos.'}',
      confirmLabel: support.isEmpty ? 'Entendido' : 'Escribir por WhatsApp',
    );
    if (!contact || support.isEmpty) return;
    final opened = await ExternalLinks.whatsapp(
      support,
      text: 'Hola, quiero eliminar mi cuenta de socio de $brandName.',
    );
    if (!opened && context.mounted) AppToast.show(context, 'No pudimos abrir WhatsApp.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider.select((s) => s.value));
    final modes = ref.watch(availablePartnerModesForProvider);
    final active = ref.watch(activePartnerModeProvider);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppAvatar(
                  imageUrl: user?.avatarUrl,
                  initials: user?.initials,
                  seed: user?.id,
                  size: 64,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (active != null)
                        Text(
                          _label(active),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      Text(
                        user?.fullName.trim() ?? '',
                        style: theme.textTheme.titleLarge,
                      ),
                      if (user != null)
                        Text(
                          user.phone.display,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (modes.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Entrar como', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<PartnerMode>(
                segments: [
                  for (final m in modes) ButtonSegment(value: m, label: Text(_label(m))),
                ],
                selected: active == null ? const {} : {active},
                onSelectionChanged: (selection) {
                  ref.read(partnerModePreferenceProvider.notifier).set(selection.first).ignore();
                  Navigator.of(context).pop();
                },
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.secondary(
              label: 'Cerrar sesión',
              onPressed: () => _logout(context, ref),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => _deleteAccount(context, ref),
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              child: const Text('Eliminar mi cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
