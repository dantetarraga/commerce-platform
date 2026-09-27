import 'package:chaski/app/config/theme_mode_provider.dart';
import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/addresses/addresses.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/favorites/favorites.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Tú": lo mío. Pedidos, direcciones, pagos, favoritos y ajustes.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const name = 'profile';

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '¿Cerrar sesión?',
      message: 'Tu bolsa se queda guardada en este celular. Para pedir tendrás que entrar de nuevo.',
      confirmLabel: 'Cerrar sesión',
      destructive: true,
    );
    // El router redirige a la entrada cuando la sesión queda vacía.
    if (confirmed) await ref.read(authSessionProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider).value;
    final history = ref.watch(ordersHistoryProvider).value;
    final active = ref.watch(activeOrderProvider).value;
    final addresses = ref.watch(addressBookControllerProvider).value?.addresses.length ?? 0;
    final themeMode = ref.watch(appThemeModeProvider);
    final favorites = ref.watch(favoritesProvider).value;
    final favoriteCount = favorites == null ? 0 : favorites.storeIds.length + favorites.productIds.length;

    final activeCount = {
      ...?history?.where((o) => o.isActive).map((o) => o.id),
      if (active != null && active.isActive) active.id,
    }.length;
    final saved = history?.fold(const Money.zero(), (sum, o) => sum + o.discount);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xxl),
          children: [
            if (user != null)
              Row(
                children: [
                  AppAvatar(imageUrl: user.avatarUrl, initials: user.initials, seed: user.id, size: 64),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(user.fullName, style: theme.textTheme.headlineSmall)),
                        Text(
                          '+51 ${_phone(user.phone.value)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: AppTypography.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ajustes de tu cuenta',
                    style: IconButton.styleFrom(backgroundColor: context.chaski.raised),
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => AppToast.show(context, 'Muy pronto: editar tu nombre y foto.'),
                  ),
                ],
              ),
            if (history != null && history.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _Stat(value: '${history.length}', label: history.length == 1 ? 'pedido' : 'pedidos'),
                  ),
                  if (favoriteCount > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: _Stat(value: '$favoriteCount', label: favoriteCount == 1 ? 'favorito' : 'favoritos')),
                  ],
                  if (saved != null && !saved.isZero) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _Stat(value: _shortMoney(saved), label: 'ahorrado'),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _Group(
              children: [
                _Row(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Mis pedidos',
                  trailing: activeCount == 0 ? null : _LimeTag('$activeCount EN CURSO'),
                  onTap: () => context.goNamed(OrdersPage.name),
                ),
                _Row(
                  icon: Icons.place_outlined,
                  title: 'Direcciones',
                  subtitle: addresses == 0 ? 'Agrega dónde te llevamos los pedidos' : '$addresses guardada${addresses == 1 ? '' : 's'}',
                  onTap: () => showAddressPicker(context),
                ),
                _Row(
                  icon: Icons.credit_card_rounded,
                  title: 'Pagos',
                  subtitle: 'Yape, Plin o efectivo al recibir',
                  onTap: () => AppToast.show(context, 'Eliges cómo pagar en cada pedido. Recordamos el último.'),
                ),
                _Row(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Favoritos',
                  onTap: () => context.pushNamed('favorites'),
                ),
                _Row(
                  icon: Icons.notifications_none_rounded,
                  title: 'Avisos',
                  onTap: () => context.pushNamed('notifications'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Group(
              children: [
                _Row(
                  icon: Icons.dark_mode_outlined,
                  title: 'Tema',
                  subtitle: _themeLabel(themeMode),
                  onTap: () => _pickTheme(context, ref, themeMode),
                ),
                _Row(
                  icon: Icons.help_outline_rounded,
                  title: 'Ayuda',
                  subtitle: 'Problemas con un pedido, pagos o tu cuenta',
                  // Con pedidos, la ayuda arranca desde el más reciente.
                  onTap: () {
                    if (history == null || history.isEmpty) {
                      AppToast.show(context, 'Muy pronto: ayuda por WhatsApp con alguien de aquí.');
                    } else {
                      context.pushNamed(OrderHelpPage.name, pathParameters: {'orderId': history.first.id}).ignore();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.ghost(
              label: 'Cerrar sesión',
              icon: Icons.logout_rounded,
              expand: true,
              onPressed: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Column(
                children: [
                  const ChaskiLogo(size: 24),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Hecho en Espinar · v0.1.0', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Igual que tu teléfono',
    ThemeMode.light => 'Claro',
    ThemeMode.dark => 'Oscuro',
  };

  Future<void> _pickTheme(BuildContext context, WidgetRef ref, ThemeMode current) async {
    final picked = await showAppBottomSheet<ThemeMode>(
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
                  RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(_themeLabel(mode)),
                    contentPadding: AppSpacing.screen,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
    if (picked != null) await ref.read(appThemeModeProvider.notifier).set(picked);
  }

  String _phone(String digits) =>
      digits.length == 9 ? '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}' : digits;

  /// "S/ 18" si no hay céntimos; si no, el monto completo.
  String _shortMoney(Money m) {
    final text = Formatters.money(m);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.tile),
        child: Column(
          children: [
            Text(value, style: AppTypography.price(context)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta lima con texto tinta ("1 EN CURSO").
class _LimeTag extends StatelessWidget {
  const _LimeTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final chaski = context.chaski;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: chaski.accent, borderRadius: const BorderRadius.all(AppRadius.sm)),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: chaski.onAccent, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Tarjeta con borde que agrupa filas separadas por líneas finas.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.onTap, this.subtitle, this.trailing});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: context.chaski.raised, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              ?trailing,
              const SizedBox(width: AppSpacing.xxs),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
