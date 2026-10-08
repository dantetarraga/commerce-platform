import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/merchant_orders/domain/merchant_board.dart';
import 'package:apamuy/features/orders/domain/staff_order.dart';
import 'package:equatable/equatable.dart';

/// Un negocio del socio, con su interruptor de "recibiendo pedidos".
final class MerchantStore extends Equatable {
  const MerchantStore({
    required this.id,
    required this.name,
    required this.isAcceptingOrders,
    required this.isOpenNow,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final bool isAcceptingOrders;
  final bool isOpenNow;

  MerchantStore copyWith({bool? isAcceptingOrders}) => MerchantStore(
    id: id,
    name: name,
    logoUrl: logoUrl,
    isAcceptingOrders: isAcceptingOrders ?? this.isAcceptingOrders,
    isOpenNow: isOpenNow,
  );

  @override
  List<Object?> get props => [id, name, logoUrl, isAcceptingOrders, isOpenNow];
}

final class MerchantProduct extends Equatable {
  const MerchantProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
    this.section,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final Money price;

  /// Sección del menú ("Bebidas"), o null si no tiene.
  final String? section;
  final bool isAvailable;

  MerchantProduct copyWith({bool? isAvailable}) => MerchantProduct(
    id: id,
    name: name,
    imageUrl: imageUrl,
    price: price,
    section: section,
    isAvailable: isAvailable ?? this.isAvailable,
  );

  @override
  List<Object?> get props => [id, name, imageUrl, price, section, isAvailable];
}

/// Pestañas de la carta en Socios.
enum ProductFilter { all, available, soldOut }

/// Cuántos productos hay en cada pestaña (de toda la carta, no de la búsqueda).
final class ProductCounts extends Equatable {
  const ProductCounts({required this.all, required this.available, required this.soldOut});

  final int all;
  final int available;
  final int soldOut;

  @override
  List<Object?> get props => [all, available, soldOut];
}

final class ProductSection extends Equatable {
  const ProductSection({required this.name, required this.items});

  final String name;
  final List<MerchantProduct> items;

  @override
  List<Object?> get props => [name, items];
}

/// La carta tal como la arma el backend para un filtro y una búsqueda: los
/// conteos de las pestañas y los productos agrupados en el orden del menú.
final class MerchantCatalog extends Equatable {
  const MerchantCatalog({required this.counts, required this.sections});

  final ProductCounts counts;
  final List<ProductSection> sections;

  @override
  List<Object?> get props => [counts, sections];
}

/// Cómo va el día del negocio. Todo lo calcula el backend (`GET /merchant/summary`).
final class MerchantSummary extends Equatable {
  const MerchantSummary({
    required this.deliveredCount,
    required this.cancelledCount,
    required this.activeCount,
    required this.sales,
    this.averageTicket,
    this.averagePrepMinutes,
    this.peakHour,
    this.salesByHour = const [],
    this.payments = const [],
    this.topProducts = const [],
  });

  final int deliveredCount;
  final int cancelledCount;
  final int activeCount;

  /// Suma de lo vendido en pedidos entregados (sin el envío).
  final Money sales;

  /// Por pedido entregado; null sin entregas.
  final Money? averageTicket;

  /// De aceptado a listo; null si ninguno llegó a listo.
  final int? averagePrepMinutes;

  /// Hora local (0–23) con más ventas.
  final int? peakHour;

  /// Horas seguidas desde la primera hasta la última con ventas.
  final List<HourSales> salesByHour;

  /// Efectivo, Yape y Plin (y tarjeta si hubo), con porcentajes que suman 100.
  final List<PaymentSales> payments;

  /// Los más vendidos por unidades.
  final List<ProductSales> topProducts;

  /// Comandas del día: entregadas más en curso (las canceladas no cuentan).
  int get totalCount => deliveredCount + activeCount;

  @override
  List<Object?> get props => [
    deliveredCount,
    cancelledCount,
    activeCount,
    sales,
    averageTicket,
    averagePrepMinutes,
    peakHour,
    salesByHour,
    payments,
    topProducts,
  ];
}

final class HourSales extends Equatable {
  const HourSales({required this.hour, required this.sales, required this.orders});

  final int hour;
  final Money sales;
  final int orders;

  @override
  List<Object?> get props => [hour, sales, orders];
}

enum PaymentKind {
  cash('Efectivo'),
  yape('Yape'),
  plin('Plin'),
  card('Tarjeta');

  const PaymentKind(this.label);

  final String label;
}

final class PaymentSales extends Equatable {
  const PaymentSales({required this.kind, required this.sales, required this.orders, required this.share});

  final PaymentKind kind;
  final Money sales;
  final int orders;

  /// Porcentaje entero de las ventas del día.
  final int share;

  @override
  List<Object?> get props => [kind, sales, orders, share];
}

final class ProductSales extends Equatable {
  const ProductSales({required this.name, required this.quantity, required this.sales});

  final String name;
  final int quantity;
  final Money sales;

  @override
  List<Object?> get props => [name, quantity, sales];
}

/// Tiempos de preparación (minutos) que se ofrecen al aceptar un pedido.
const prepTimeChoices = [10, 20, 30, 45];

/// Motivos rápidos para rechazar; el cliente los lee.
const rejectReasons = ['Sin stock', 'Estamos cerrando', 'Muchos pedidos'];

abstract interface class MerchantRepository {
  Future<Result<List<MerchantStore>>> stores();

  Future<Result<MerchantStore>> setAcceptingOrders(MerchantStore store, {required bool accepting});

  /// Pedidos en curso (de nuevo a en camino), del más reciente al más antiguo.
  /// Los pedidos en curso repartidos en las tres columnas, con sus conteos.
  Future<Result<MerchantBoard>> board();

  Future<Result<List<StaffOrder>>> todayOrders();

  /// Acepta y empieza a preparar; [prepMinutes] ajusta la hora estimada.
  Future<Result<StaffOrder>> accept(String orderId, {required int prepMinutes});

  Future<Result<StaffOrder>> markReady(String orderId);

  Future<Result<StaffOrder>> reject(String orderId, {required String reason});

  /// La carta con el [filter] y la búsqueda [query] aplicados por el backend.
  Future<Result<MerchantCatalog>> products(String storeId, {ProductFilter filter = ProductFilter.all, String query = ''});

  Future<Result<MerchantProduct>> setProductAvailable(MerchantProduct product, {required bool available});

  Future<Result<MerchantSummary>> summary();
}
