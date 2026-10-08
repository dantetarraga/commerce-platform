import 'package:chaski/core/domain/money.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/domain/merchant_board.dart';
import 'package:chaski/features/merchant_orders/infrastructure/models/merchant_json.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/merchant_rail.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/today_charts.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _pen(int amount) => {'amount': amount, 'currency': 'PEN'};

final _json = <String, dynamic>{
  'date': '2026-10-08',
  'deliveredCount': 2,
  'cancelledCount': 0,
  'activeCount': 1,
  'sales': _pen(4550),
  'averageTicket': _pen(2275),
  'averagePrepMinutes': 16,
  'peakHour': 13,
  'salesByHour': [
    {'hour': 12, 'sales': _pen(1550), 'orders': 1},
    {'hour': 13, 'sales': _pen(3000), 'orders': 1},
  ],
  'payments': [
    {'method': 'CASH', 'sales': _pen(3000), 'orders': 1, 'share': 66},
    {'method': 'YAPE', 'sales': _pen(1550), 'orders': 1, 'share': 34},
    {'method': 'PLIN', 'sales': _pen(0), 'orders': 0, 'share': 0},
  ],
  'topProducts': [
    {'productId': 'p1', 'name': 'Pollo', 'quantity': 3, 'sales': _pen(3000)},
  ],
};

Future<void> _pump(WidgetTester tester, Widget child, {List<Object> overrides = const []}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(theme: AppTheme.light(), home: Scaffold(body: SingleChildScrollView(child: child))),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  test('el resumen trae las gráficas del backend; uno viejo sin ellas no falla', () {
    final summary = MerchantJson.summary(_json);
    expect(summary.averageTicket, const Money(2275));
    expect(summary.averagePrepMinutes, 16);
    expect(summary.peakHour, 13);
    expect(summary.salesByHour.map((h) => h.hour), [12, 13]);
    expect(summary.payments.map((p) => (p.kind, p.share)), [
      (PaymentKind.cash, 66),
      (PaymentKind.yape, 34),
      (PaymentKind.plin, 0),
    ]);
    expect(summary.topProducts.single.name, 'Pollo');

    final old = MerchantJson.summary({..._json}..removeWhere((k, _) => !{'deliveredCount', 'cancelledCount', 'activeCount', 'sales'}.contains(k)));
    expect(old.salesByHour, isEmpty);
    expect(old.averageTicket, isNull);
  });

  testWidgets('las gráficas muestran la hora pico, los pagos y lo más pedido', (tester) async {
    final summary = MerchantJson.summary(_json);
    await _pump(
      tester,
      Column(
        children: [
          TodayHeadline(summary: summary),
          SalesByHourChart(hours: summary.salesByHour, peakHour: summary.peakHour),
          PaymentsBar(payments: summary.payments),
          TopProductsChart(products: summary.topProducts),
        ],
      ),
    );
    expect(find.text('S/ 22.75'), findsOneWidget);
    expect(find.text('16 min'), findsOneWidget);
    expect(find.textContaining('Hora pico 13:00'), findsOneWidget);
    expect(find.text('Efectivo · 66 %'), findsOneWidget);
    expect(find.text('Pollo'), findsOneWidget);

    // Tocar otra hora muestra su detalle.
    // La columna está justo encima de su hora.
    await tester.tapAt(tester.getCenter(find.text('12')) - const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('A las 12:00'), findsOneWidget);
  });

  testWidgets('cada columna vacía tiene su ícono y su dato del momento', (tester) async {
    final board = {for (final c in MerchantBoardColumn.values) c: <StaffOrder>[]};
    await _pump(
      tester,
      const Column(
        children: [
          MerchantColumnEmpty(column: MerchantBoardColumn.fresh),
          MerchantColumnEmpty(column: MerchantBoardColumn.ready),
        ],
      ),
      overrides: [
        merchantBoardProvider.overrideWithValue(AsyncData(board)),
        merchantSummaryProvider.overrideWith((ref) async => MerchantJson.summary(_json)),
        merchantStoresProvider.overrideWith(_Stores.new),
      ],
    );
    expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
    expect(find.byIcon(Icons.takeout_dining_rounded), findsOneWidget);
    expect(find.text('Recibiendo pedidos · alarma lista'), findsOneWidget);
    expect(find.text('Hoy salieron 2'), findsOneWidget);
  });
}

class _Stores extends MerchantStores {
  @override
  Future<List<MerchantStore>> build() async => const [
    MerchantStore(id: 's1', name: 'Doña Rosa', isAcceptingOrders: true, isOpenNow: true),
  ];
}
