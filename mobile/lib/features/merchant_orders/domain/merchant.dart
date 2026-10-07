import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/orders/domain/staff_order.dart';
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

/// Cómo va el día del negocio.
final class MerchantSummary extends Equatable {
  const MerchantSummary({
    required this.deliveredCount,
    required this.cancelledCount,
    required this.activeCount,
    required this.sales,
  });

  final int deliveredCount;
  final int cancelledCount;
  final int activeCount;

  /// Suma de lo vendido en pedidos entregados (sin el envío).
  final Money sales;

  /// Comandas del día: entregadas más en curso (las canceladas no cuentan).
  int get totalCount => deliveredCount + activeCount;

  @override
  List<Object?> get props => [deliveredCount, cancelledCount, activeCount, sales];
}

/// Tiempos de preparación (minutos) que se ofrecen al aceptar un pedido.
const prepTimeChoices = [10, 20, 30, 45];

/// Motivos rápidos para rechazar; el cliente los lee.
const rejectReasons = ['Sin stock', 'Estamos cerrando', 'Cocina llena'];

abstract interface class MerchantRepository {
  Future<Result<List<MerchantStore>>> stores();

  Future<Result<MerchantStore>> setAcceptingOrders(MerchantStore store, {required bool accepting});

  /// Pedidos en curso (de nuevo a en camino), del más reciente al más antiguo.
  Future<Result<List<StaffOrder>>> activeOrders();

  Future<Result<List<StaffOrder>>> todayOrders();

  /// Acepta y empieza a preparar; [prepMinutes] ajusta la hora estimada.
  Future<Result<StaffOrder>> accept(String orderId, {required int prepMinutes});

  Future<Result<StaffOrder>> markReady(String orderId);

  Future<Result<StaffOrder>> reject(String orderId, {required String reason});

  Future<Result<List<MerchantProduct>>> products(String storeId);

  Future<Result<MerchantProduct>> setProductAvailable(MerchantProduct product, {required bool available});

  Future<Result<MerchantSummary>> summary();
}
