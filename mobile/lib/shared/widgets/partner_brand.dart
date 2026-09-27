import 'dart:async';
import 'dart:math' as math;

import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Piezas de marca de Chaski Socios: la portada con la foto en círculo y el trazo,
/// la píldora de estado, las pestañas en píldora, el temporizador, el sello, el
/// trazo con estaciones y el riel de comandas.

/// Portada a todo el ancho: etiqueta, saludo, titular con su remate en terracota y la
/// foto o el avatar en círculo con anillo punteado. [pill] monta el borde inferior.
class PartnerHero extends StatelessWidget {
  const PartnerHero({
    required this.eyebrow,
    required this.title,
    required this.accent,
    this.greeting,
    this.subtitle,
    this.imageUrl,
    this.avatar,
    this.actions = const [],
    this.pill,
    super.key,
  });

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

  static const _pillOverlap = 30.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    final showArt = (imageUrl != null || avatar != null) && MediaQuery.textScalerOf(context).scale(16) < 20;
    final hero = Container(
      width: double.infinity,
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.hero),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (showArt)
            Positioned(
              right: -34,
              top: top + 52,
              child: ExcludeSemantics(
                child: _HeroArt(imageUrl: imageUrl, avatar: avatar),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HeroTrail(color: scheme.primary, start: context.chaski.accent, ring: scheme.primaryContainer),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, top + 12, AppSpacing.gutter, pill == null ? 26 : _pillOverlap + 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(color: scheme.surface, borderRadius: AppRadius.button),
                          child: Text(
                            eyebrow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...actions,
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(right: showArt ? 130 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (greeting != null)
                        Text(
                          greeting!,
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
                              TextSpan(
                                text: accent,
                                style: TextStyle(color: scheme.primary),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontFamily: AppTypography.display,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 0.98,
                            letterSpacing: -0.8,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(subtitle!.replaceAll('S/ ', 'S/ '), style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (pill == null) return hero;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: _pillOverlap),
          child: hero,
        ),
        Positioned(left: AppSpacing.gutter, right: AppSpacing.gutter, bottom: 0, child: pill!),
      ],
    );
  }
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
            child: CustomPaint(painter: DashedRingPainter(color: scheme.primary.withValues(alpha: 0.35))),
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
          Positioned(
            left: 12,
            top: 16,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: context.chaski.accent,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primaryContainer, width: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trazo punteado que sale abajo a la izquierda de la portada.
class _HeroTrail extends CustomPainter {
  const _HeroTrail({required this.color, required this.start, required this.ring});

  final Color color;
  final Color start;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 300) return;
    final y = size.height - 40;
    final from = Offset(24, y);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(size.width * 0.35, y, size.width * 0.5, y - 4, size.width * 0.7, y - 34);
    final metric = path.computeMetrics().first;
    final dot = Paint()..color = color;
    for (var d = 0.0; d < metric.length; d += 9) {
      final p = metric.getTangentForOffset(d)?.position;
      if (p != null) canvas.drawCircle(p, 1.6, dot);
    }
    canvas
      ..drawCircle(from, 7.5, Paint()..color = ring)
      ..drawCircle(from, 6, Paint()..color = start);
  }

  @override
  bool shouldRepaint(_HeroTrail old) => old.color != color || old.start != start || old.ring != ring;
}

/// Anillo punteado alrededor de una foto o un avatar.
class DashedRingPainter extends CustomPainter {
  const DashedRingPainter({required this.color, this.dashes = 40});

  final Color color;
  final int dashes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final side = math.min(size.width, size.height);
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: side - 2, height: side - 2);
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * 2 * math.pi / dashes, math.pi / dashes, false, paint);
    }
  }

  @override
  bool shouldRepaint(DashedRingPainter old) => old.color != color || old.dashes != dashes;
}

/// "Cocina abierta · recibiendo" / "En ruta · conectado": verde cuando está activo.
class PartnerStatusPill extends StatelessWidget {
  const PartnerStatusPill({
    required this.title,
    required this.message,
    required this.value,
    required this.onChanged,
    this.busy = false,
    super.key,
  });

  final String title;
  final String message;
  final bool value;
  final bool busy;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final on = value;
    final bg = on ? AppColors.hierba : scheme.surface;
    final fg = on ? AppColors.blanco : scheme.onSurface;
    return Material(
      color: bg,
      borderRadius: AppRadius.tileExit,
      shadowColor: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.tileExit,
        onTap: busy || onChanged == null ? null : () => onChanged!(!value),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(borderRadius: AppRadius.tileExit, boxShadow: AppShadows.raised(theme.brightness)),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: on ? AppColors.blanco : scheme.onSurfaceVariant, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(color: on ? const Color(0xFFEFF6EB) : scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              else
                Semantics(
                  label: title,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: AppColors.blanco,
                    activeTrackColor: AppColors.blanco.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pestañas en píldora conectadas al [TabController] más cercano.
class PartnerPillTabs extends StatelessWidget implements PreferredSizeWidget {
  const PartnerPillTabs({required this.labels, super.key});

  final List<String> labels;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 8),
        child: Row(
          children: [
            for (final (i, label) in labels.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Semantics(
                selected: controller.index == i,
                button: true,
                child: Material(
                  color: controller.index == i ? scheme.primary : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.button,
                    side: BorderSide(color: controller.index == i ? scheme.primary : scheme.outlineVariant, width: 1.5),
                  ),
                  child: InkWell(
                    borderRadius: AppRadius.button,
                    onTap: () => controller.animateTo(i),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: controller.index == i ? scheme.onPrimary : scheme.onSurface,
                          fontWeight: controller.index == i ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tiempo que queda para responder, en un anillo que se vacía. Se pone rojo al acabarse.
class CountdownRing extends StatefulWidget {
  const CountdownRing({required this.deadline, required this.total, this.size = 64, super.key});

  final DateTime deadline;
  final Duration total;
  final double size;

  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final left = widget.deadline.difference(DateTime.now());
    final seconds = left.inSeconds.clamp(0, widget.total.inSeconds);
    final fraction = widget.total.inSeconds == 0 ? 0.0 : seconds / widget.total.inSeconds;
    final urgent = seconds <= 120;
    final color = urgent ? context.chaski.danger : scheme.primary;
    final label = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Semantics(
      label: 'Quedan $label para responder',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _RingPainter(fraction: fraction, color: color, track: scheme.primaryContainer),
          child: Center(
            child: Text(
              label,
              style: AppTypography.price(context, size: widget.size * 0.28).copyWith(color: urgent ? color : scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction, required this.color, required this.track});

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas
      ..drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      )
      ..drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.color != color || old.track != track;
}

/// Sello inclinado: "LISTA", "+S/ 4.50", "PARA RENDIR".
class PartnerStamp extends StatelessWidget {
  const PartnerStamp(this.text, {this.color, this.size = 13, super.key});

  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Transform.rotate(
      angle: -0.07,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: c, width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
            bottomLeft: Radius.circular(3),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppTypography.display,
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: c,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ),
    );
  }
}

/// Línea punteada del trazo (horizontal o vertical).
class DottedLine extends StatelessWidget {
  const DottedLine({this.color, this.vertical = false, this.gap = 7, this.radius = 1.6, super.key});

  final Color? color;
  final bool vertical;
  final double gap;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: vertical ? Size(radius * 2, double.infinity) : Size(double.infinity, radius * 2),
    painter: _DotsPainter(color: color ?? Theme.of(context).colorScheme.primary, vertical: vertical, gap: gap, radius: radius),
  );
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter({required this.color, required this.vertical, required this.gap, required this.radius});

  final Color color;
  final bool vertical;
  final double gap;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final length = vertical ? size.height : size.width;
    for (var d = radius; d < length; d += gap) {
      canvas.drawCircle(vertical ? Offset(size.width / 2, d) : Offset(d, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color || old.vertical != vertical || old.gap != gap || old.radius != radius;
}

/// Una parada del recorrido: el nodo a la izquierda sobre el trazo y su contenido.
class PartnerStation {
  const PartnerStation({required this.node, required this.child});

  final Widget node;
  final Widget child;
}

/// Estaciones unidas por el trazo vertical punteado.
class PartnerStations extends StatelessWidget {
  const PartnerStations({required this.stations, this.nodeWidth = 48, this.spacing = 14, super.key});

  final List<PartnerStation> stations;
  final double nodeWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, s) in stations.indexed)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: nodeWidth,
                child: Column(
                  children: [
                    s.node,
                    if (i < stations.length - 1)
                      const Expanded(
                        child: Padding(padding: EdgeInsets.symmetric(vertical: 4), child: DottedLine(vertical: true, gap: 8, radius: 1.8)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: i < stations.length - 1 ? spacing : 0),
                  child: s.child,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Nodo circular con foto (salida), ícono o check.
class StationNode extends StatelessWidget {
  const StationNode({this.imageUrl, this.icon, this.color, this.size = 44, this.square = false, this.done = false, super.key});

  final String? imageUrl;
  final IconData? icon;
  final Color? color;
  final double size;
  final bool square;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    final shape = square ? AppRadius.button : BorderRadius.circular(size / 2);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: imageUrl == null ? c : null,
              borderRadius: shape,
              border: Border.all(color: imageUrl == null ? Theme.of(context).scaffoldBackgroundColor : c, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null
                ? AppNetworkImage(url: imageUrl, width: size, height: size, fallbackIcon: Icons.storefront_rounded)
                : Icon(icon, size: size * 0.45, color: AppColors.blanco),
          ),
          if (done)
            Positioned(
              right: -4,
              bottom: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.hierba,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
                ),
                child: const Icon(Icons.check_rounded, size: 11, color: AppColors.blanco),
              ),
            ),
        ],
      ),
    );
  }
}

/// Riel de cocina con su título: las comandas cuelgan debajo.
class PartnerRail extends StatelessWidget {
  const PartnerRail({required this.title, required this.count, required this.dot, required this.children, this.empty, super.key});

  final String title;
  final int count;
  final Color dot;
  final List<Widget> children;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
            Text('$count', style: AppTypography.price(context)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5A4A42), Color(0xFF2A1A14)],
            ),
            boxShadow: [BoxShadow(color: Color(0x402A1A14), blurRadius: 6, offset: Offset(0, 3))],
          ),
        ),
        const SizedBox(height: 20),
        if (children.isEmpty && empty != null) empty!,
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const SizedBox(height: 26),
          Transform.rotate(
            angle: (i.isEven ? -0.8 : 0.6) * math.pi / 180,
            child: _Clipped(child: c),
          ),
        ],
      ],
    );
  }
}

class _Clipped extends StatelessWidget {
  const _Clipped({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      child,
      Positioned(
        top: -22,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            width: 36,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.tinta,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
          ),
        ),
      ),
    ],
  );
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

/// Botón redondo sobre la portada (productos, sonido…).
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
        style: IconButton.styleFrom(backgroundColor: scheme.surface, foregroundColor: scheme.onSurface, fixedSize: const Size.square(44)),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

/// Botón que se confirma deslizando la ficha por el trazo hasta el punto final,
/// para no marcar una entrega con un toque sin querer. Con lector de pantalla se
/// activa con un toque normal.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
    required this.onConfirm,
    this.busy = false,
    super.key,
  });

  final String label;
  final String hint;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onConfirm;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  static const _height = 64.0;
  static const _knob = 52.0;
  double _dx = 0;
  var _hinting = false;

  void _end(double max) {
    if (_dx >= max * 0.8) {
      setState(() => _dx = max);
      widget.onConfirm();
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _dx = 0);
      });
    } else {
      setState(() {
        _dx = 0;
        _hinting = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final max = constraints.maxWidth - _knob - 12;
        final enabled = !widget.busy;
        return Semantics(
          button: true,
          enabled: enabled,
          label: widget.label,
          hint: widget.hint,
          excludeSemantics: true,
          onTap: enabled ? widget.onConfirm : null,
          child: GestureDetector(
            onTap: enabled ? () => setState(() => _hinting = true) : null,
            onHorizontalDragUpdate: enabled ? (d) => setState(() => _dx = (_dx + d.delta.dx).clamp(0, max)) : null,
            onHorizontalDragEnd: enabled ? (_) => _end(max) : null,
            child: Container(
              height: _height,
              width: double.infinity,
              decoration: BoxDecoration(color: widget.color, borderRadius: AppRadius.button),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: _knob + 18,
                    right: 22,
                    child: DottedLine(color: AppColors.blanco.withValues(alpha: 0.45), gap: 10),
                  ),
                  Positioned(
                    right: 16,
                    child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: AppColors.blanco, shape: BoxShape.circle)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: _knob + 12, right: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: theme.textTheme.titleSmall?.copyWith(color: AppColors.blanco, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          _hinting ? 'Desliza la ficha hasta el final' : widget.hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.blanco.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _dx == 0 ? AppMotion.move : Duration.zero,
                    curve: AppMotion.arrive,
                    left: 6 + _dx,
                    top: 6,
                    child: Container(
                      width: _knob,
                      height: _knob,
                      decoration: const BoxDecoration(
                        color: AppColors.blanco,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                          bottomLeft: Radius.circular(5),
                        ),
                      ),
                      child: widget.busy
                          ? Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: widget.color)))
                          : Icon(_dx > 0 ? Icons.arrow_forward_rounded : widget.icon, color: widget.color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
