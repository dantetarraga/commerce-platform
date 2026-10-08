import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/merchant_orders/domain/merchant.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/partner/partner.dart';
import 'package:flutter/material.dart';

/// Lo vendido en grande y tres datos del día: pedidos, ticket y preparación.
class TodayHeadline extends StatelessWidget {
  const TodayHeadline({required this.summary, super.key});

  final MerchantSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimaryContainer;
    final prep = summary.averagePrepMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: AppRadius.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vendido hoy', style: theme.textTheme.bodyMedium?.copyWith(color: on)),
              Text(Formatters.money(summary.sales), style: theme.textTheme.headlineLarge?.copyWith(color: on)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Entregados',
                value: '${summary.deliveredCount}',
                note: summary.cancelledCount == 1 ? '1 cancelado' : '${summary.cancelledCount} cancelados',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _Stat(
                label: 'Ticket prom.',
                value: summary.averageTicket == null ? '—' : Formatters.money(summary.averageTicket!),
                note: 'por pedido',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _Stat(label: 'Preparas en', value: prep == null ? '—' : '$prep min', note: 'promedio'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.note});

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return PartnerSurface(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: muted), maxLines: 1, overflow: TextOverflow.ellipsis),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: theme.textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          Text(note, style: theme.textTheme.labelSmall?.copyWith(color: muted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Tarjeta de una gráfica: título, una línea que dice qué mide y el contenido.
class TodayChartCard extends StatelessWidget {
  const TodayChartCard({required this.title, required this.subtitle, required this.child, super.key});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PartnerSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Columnas de lo vendido por hora. La hora pico va llena y su monto arriba;
/// al tocar otra columna se ve su hora, monto y pedidos.
class SalesByHourChart extends StatefulWidget {
  const SalesByHourChart({required this.hours, required this.peakHour, super.key});

  final List<HourSales> hours;
  final int? peakHour;

  @override
  State<SalesByHourChart> createState() => _SalesByHourChartState();
}

class _SalesByHourChartState extends State<SalesByHourChart> {
  int? _selected;

  static const _plotHeight = 120.0;

  /// Tope del eje redondeado a 50 soles para ticks limpios.
  static int _topCents(int max) => max <= 0 ? 5000 : (max / 5000).ceil() * 5000;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final axis = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 10);
    final hours = widget.hours;
    final top = _topCents(hours.fold<int>(0, (m, h) => h.sales.cents > m ? h.sales.cents : m));
    final focus = hours.where((h) => h.hour == (_selected ?? widget.peakHour)).firstOrNull;
    final caption = focus == null
        ? ''
        : '${focus.hour == widget.peakHour && _selected == null ? 'Hora pico' : 'A las'} ${focus.hour}:00 · '
              '${Formatters.money(focus.sales)} · ${focus.orders} ${focus.orders == 1 ? 'pedido' : 'pedidos'}';
    final motion = reduceMotionOf(context) ? Duration.zero : AppMotion.quick;

    Widget gridLine(int cents) => Row(
      children: [
        SizedBox(width: 28, child: Text('${cents ~/ 100}', style: axis, textAlign: TextAlign.right)),
        const SizedBox(width: 6),
        Expanded(child: Container(height: 1, color: scheme.outlineVariant)),
      ],
    );

    return Semantics(
      label: focus == null ? 'Sin ventas por hora' : 'Ventas por hora. $caption.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // El monto va en texto con tinta, nunca del color de la barra.
          Text(caption, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: _plotHeight,
            child: Stack(
              // Las etiquetas del eje se centran en su línea y asoman por arriba.
              clipBehavior: Clip.none,
              children: [
                for (final (i, cents) in [top, top ~/ 2, 0].indexed)
                  Positioned(left: 0, right: 0, top: i * (_plotHeight - 1) / 2 - 6, child: gridLine(cents)),
                Positioned.fill(
                  left: 34,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final slot in hours)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _selected = _selected == slot.hour ? null : slot.hour),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: motion,
                                width: 14,
                                height: (_plotHeight - 1) * slot.sales.cents / top,
                                decoration: BoxDecoration(
                                  color: slot.hour == focus?.hour ? scheme.primary : scheme.primary.withValues(alpha: 0.45),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Row(
              children: [
                for (final slot in hours)
                  Expanded(
                    child: Text(
                      // Una hora sí y otra no cuando son muchas, para que no se amontonen.
                      hours.length > 7 && (slot.hour - hours.first.hour).isOdd ? '' : '${slot.hour}',
                      style: axis,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Colores de los métodos de pago, validados para daltonismo (claro y oscuro).
Color paymentColor(PaymentKind kind, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (kind) {
    PaymentKind.cash => dark ? const Color(0xFFE0683F) : const Color(0xFFC2502E),
    PaymentKind.yape => dark ? const Color(0xFF3987E5) : const Color(0xFF2A78D6),
    PaymentKind.plin => dark ? const Color(0xFF2FAE79) : const Color(0xFF2E9E6A),
    PaymentKind.card => dark ? AppColors.nochePiedra : AppColors.piedra,
  };
}

/// Una barra partida por método de pago, con 2 px entre tramos, y la leyenda
/// con el monto de cada uno.
class PaymentsBar extends StatelessWidget {
  const PaymentsBar({required this.payments, super.key});

  final List<PaymentSales> payments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final paid = payments.where((p) => p.share > 0).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: payments.map((p) => '${p.kind.label} ${Formatters.money(p.sales)}, ${p.share} %').join('. '),
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: SizedBox(
                height: 22,
                child: Row(
                  children: [
                    for (final (i, p) in paid.indexed) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Expanded(
                        flex: p.share,
                        child: ColoredBox(color: paymentColor(p.kind, brightness), child: const SizedBox.expand()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final p in payments)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: paymentColor(p.kind, brightness), borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text('${p.kind.label} · ${p.share} %', style: theme.textTheme.bodyMedium)),
                Text(
                  Formatters.money(p.sales),
                  style: theme.textTheme.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Barras horizontales de los más vendidos, con las unidades en la punta.
class TopProductsChart extends StatelessWidget {
  const TopProductsChart({required this.products, super.key});

  final List<ProductSales> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final max = products.fold<int>(1, (m, p) => p.quantity > m ? p.quantity : m);
    return Column(
      children: [
        for (final (i, p) in products.indexed)
          Semantics(
            label: '${p.name}: ${p.quantity} unidades',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      p.name,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Deja lugar al número en la punta de la barra más larga.
                        final width = (constraints.maxWidth - 32) * p.quantity / max;
                        return Row(
                          children: [
                            Container(
                              width: width.clamp(4, constraints.maxWidth),
                              height: 14,
                              decoration: BoxDecoration(
                                color: i == 0 ? scheme.primary : scheme.primary.withValues(alpha: 0.5),
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('${p.quantity}', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
