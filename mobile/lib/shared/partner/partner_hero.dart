import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/core/utils/text_scale.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Portada a todo el ancho de Apamuy Socios: etiqueta, saludo, titular con su
/// remate en terracota y la foto o el avatar en círculo. [pill] monta el borde
/// inferior.
class PartnerHero extends StatelessWidget {
  /// [subtitle] se prepara una sola vez aquí (el "S/" no se separa del monto
  /// al partir la línea), no en cada `build`.
  PartnerHero({
    required this.eyebrow,
    required this.title,
    required this.accent,
    this.greeting,
    String? subtitle,
    this.imageUrl,
    this.avatar,
    this.actions = const [],
    this.pill,
    this.subtitleLoading = false,
    super.key,
  }) : subtitle = subtitle == null ? null : Formatters.keepCurrencyTogether(subtitle);

  final String eyebrow;
  final String? greeting;

  /// "Tu cocina," · "Yauri te"
  final String title;

  /// "al toque." · "espera." (en terracota, en otra línea).
  final String accent;
  final String? subtitle;
  final String? imageUrl;
  final Widget? avatar;
  final List<Widget> actions;
  final Widget? pill;

  /// Reserva la línea del subtítulo mientras llegan los números del día.
  final bool subtitleLoading;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final showArt = (imageUrl != null || avatar != null) && !isLargeText(context);
    final hero = Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: AppRadius.hero),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (showArt)
            Positioned(
              right: -34,
              top: top + 52,
              child: ExcludeSemantics(child: _HeroArt(imageUrl: imageUrl, avatar: avatar)),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, top + 12, AppSpacing.gutter, this.pill == null ? 26 : _PillOverlap.overlap + 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _HeroEyebrow(eyebrow)),
                    ...actions,
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(right: showArt ? 130 : 0),
                  child: _HeroHeadline(
                    greeting: greeting,
                    title: title,
                    accent: accent,
                    subtitle: subtitle,
                    subtitleLoading: subtitleLoading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final pill = this.pill;
    return pill == null ? hero : _PillOverlap(hero: hero, pill: pill);
  }
}

/// La etiqueta en cápsula clara arriba a la izquierda ("APAMUY SOCIOS · COCINA").
class _HeroEyebrow extends StatelessWidget {
  const _HeroEyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: scheme.surface, borderRadius: AppRadius.button),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimaryContainer, letterSpacing: 1.2, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// Saludo, titular de dos líneas (la segunda en terracota) y subtítulo.
class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline({
    required this.title,
    required this.accent,
    required this.subtitleLoading,
    this.greeting,
    this.subtitle,
  });

  final String? greeting;
  final String title;
  final String accent;
  final String? subtitle;
  final bool subtitleLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final greeting = this.greeting;
    final subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (greeting != null)
          Text(
            greeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800),
          ),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$title\n'),
                TextSpan(text: accent, style: TextStyle(color: scheme.primary)),
              ],
            ),
            style: AppTypography.displayStyle(context, size: 34, weight: FontWeight.w800, height: 0.98, letterSpacing: -0.8),
          ),
        ),
        if (subtitle == null && subtitleLoading) ...[
          const SizedBox(height: 10),
          const Skeleton(child: SkeletonBox(width: 210)),
          const SizedBox(height: 2),
        ] else if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

/// Monta [pill] sobre el borde inferior de la portada.
class _PillOverlap extends StatelessWidget {
  const _PillOverlap({required this.hero, required this.pill});

  /// Cuánto de la píldora queda bajo la portada.
  static const overlap = 30.0;

  final Widget hero;
  final Widget pill;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Padding(padding: const EdgeInsets.only(bottom: overlap), child: hero),
      Positioned(left: AppSpacing.gutter, right: AppSpacing.gutter, bottom: 0, child: pill),
    ],
  );
}

class _HeroArt extends StatelessWidget {
  const _HeroArt({this.imageUrl, this.avatar});

  final String? imageUrl;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 170,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle)),
          ),
          Positioned(
            left: 20,
            top: 20,
            child:
                avatar ??
                AppNetworkImage(
                  url: imageUrl,
                  width: 130,
                  height: 130,
                  borderRadius: const BorderRadius.all(Radius.circular(65)),
                  fallbackIcon: Icons.storefront_rounded,
                ),
          ),
        ],
      ),
    );
  }
}

/// Botón redondo sobre la portada (productos, sonido…), de 48 px de área táctil.
class PartnerHeroAction extends StatelessWidget {
  const PartnerHeroAction({required this.icon, required this.tooltip, required this.onPressed, super.key});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          fixedSize: const Size.square(AppSpacing.minTouch),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

/// "Buenos días" · "Buenas tardes" · "Buenas noches", según la hora.
String partnerGreeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour >= 5 && hour < 12) return 'Buenos días';
  if (hour >= 12 && hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

/// Barra superior mínima con el tono de la portada: la portada arranca justo debajo
/// de la hora del teléfono y las pestañas fijas no se meten bajo ella.
PreferredSizeWidget partnerStatusBar(BuildContext context) => AppBar(
  toolbarHeight: 0,
  automaticallyImplyLeading: false,
  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
  surfaceTintColor: Colors.transparent,
  scrolledUnderElevation: 0,
  elevation: 0,
);
