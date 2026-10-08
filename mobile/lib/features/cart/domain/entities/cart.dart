import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/domain/quantity.dart';
import 'package:equatable/equatable.dart';

/// Negocio de la bolsa, tal como se vio al agregar el primer producto. El
/// backend recalcula envío y mínimo al confirmar.
final class CartStore extends Equatable {
  const CartStore({
    required this.id,
    required this.name,
    required this.deliveryFee,
    required this.minOrderAmount,
    required this.etaMinutes,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final Money deliveryFee;
  final Money minOrderAmount;
  final int etaMinutes;

  @override
  List<Object?> get props => [id, name, logoUrl, deliveryFee, minOrderAmount, etaMinutes];
}

/// Una opción elegida ("Papas nativas +S/ 4.00").
final class CartChoice extends Equatable {
  const CartChoice({required this.optionId, required this.valueId, required this.label, required this.priceDelta});

  final String optionId;
  final String valueId;
  final String label;
  final Money priceDelta;

  @override
  List<Object?> get props => [optionId, valueId, label, priceDelta];
}

/// Producto configurado dentro de la bolsa.
final class CartLine extends Equatable {
  const CartLine({
    required this.id,
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.variantId,
    this.variantName,
    this.choices = const [],
    this.notes = '',
  });

  final String id;
  final String productId;
  final String name;
  final String? imageUrl;
  final String? variantId;
  final String? variantName;
  final List<CartChoice> choices;

  /// Precio unitario con variante y opciones.
  final Money unitPrice;
  final Quantity quantity;
  final String notes;

  Money get total => unitPrice * quantity.value;

  /// "Grande · Mote, Cancha" para mostrar bajo el nombre.
  String get description => [?variantName, ...choices.map((c) => c.label)].join(' · ');

  /// Misma configuración (producto, variante, opciones y nota): al agregarla
  /// otra vez se suma la cantidad en vez de crear otra línea.
  bool sameConfigurationAs(CartLine other) =>
      productId == other.productId &&
      variantId == other.variantId &&
      notes.trim() == other.notes.trim() &&
      _choiceKey == other._choiceKey;

  String get _choiceKey => (choices.map((c) => '${c.optionId}:${c.valueId}').toList()..sort()).join('|');

  CartLine copyWith({Quantity? quantity, String? notes}) => CartLine(
    id: id,
    productId: productId,
    name: name,
    imageUrl: imageUrl,
    variantId: variantId,
    variantName: variantName,
    choices: choices,
    unitPrice: unitPrice,
    quantity: quantity ?? this.quantity,
    notes: notes ?? this.notes,
  );

  @override
  List<Object?> get props => [id, productId, name, imageUrl, variantId, variantName, choices, unitPrice, quantity, notes];
}

/// Cupón ya validado por el backend.
final class Coupon extends Equatable {
  const Coupon({required this.code, required this.discount, required this.label});

  final String code;
  final Money discount;

  /// "S/ 5 de bienvenida".
  final String label;

  @override
  List<Object?> get props => [code, discount, label];
}

/// Resultado de intentar agregar: la bolsa es de un solo negocio.
sealed class AddToCartResult {
  const AddToCartResult();
}

final class Added extends AddToCartResult {
  const Added(this.cart);
  final Cart cart;
}

/// La bolsa tiene productos de otro negocio: hay que confirmar vaciarla.
final class StoreConflict extends AddToCartResult {
  const StoreConflict({required this.current, required this.incoming});
  final CartStore current;
  final CartStore incoming;
}

/// La bolsa: un negocio, sus líneas y un cupón opcional. Inmutable; los montos
/// son orientativos y el backend recalcula al confirmar.
final class Cart extends Equatable {
  const Cart({this.store, this.lines = const [], this.coupon, this.note = ''});

  static const empty = Cart();

  /// Máximo de líneas distintas (protege de bolsas absurdas).
  static const maxLines = 30;

  final CartStore? store;
  final List<CartLine> lines;
  final Coupon? coupon;

  /// Nota general para el negocio (opcional).
  final String note;

  bool get isEmpty => lines.isEmpty;

  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity.value);

  Money get subtotal => lines.fold(const Money.zero(), (sum, l) => sum + l.total);

  Money get deliveryFee => store?.deliveryFee ?? const Money.zero();

  Money get discount {
    final c = coupon;
    if (c == null) return const Money.zero();
    // El descuento nunca supera el subtotal.
    return c.discount.cents > subtotal.cents ? subtotal : c.discount;
  }

  Money get total => isEmpty ? const Money.zero() : Money(subtotal.cents + deliveryFee.cents - discount.cents);

  /// Cuánto falta para el pedido mínimo del negocio (cero si ya se alcanzó).
  Money get missingForMinimum {
    final min = store?.minOrderAmount ?? const Money.zero();
    final missing = min.cents - subtotal.cents;
    return Money(missing > 0 ? missing : 0);
  }

  bool get reachesMinimum => missingForMinimum.isZero;

  /// Progreso hacia el mínimo (0..1) para el hilo de progreso.
  double get minimumProgress {
    final min = store?.minOrderAmount.cents ?? 0;
    if (min == 0) return 1;
    return (subtotal.cents / min).clamp(0.0, 1.0);
  }

  bool get canCheckout => !isEmpty && reachesMinimum;

  AddToCartResult add(CartLine line, CartStore lineStore) {
    final current = store;
    if (current != null && current.id != lineStore.id && !isEmpty) {
      return StoreConflict(current: current, incoming: lineStore);
    }
    final index = lines.indexWhere((l) => l.sameConfigurationAs(line));
    if (index >= 0) {
      final existing = lines[index];
      final merged = Quantity.create(existing.quantity.value + line.quantity.value).valueOrNull ??
          Quantity.create(Quantity.max).valueOrNull!;
      return Added(_with(lines: [...lines]..[index] = existing.copyWith(quantity: merged), store: lineStore));
    }
    if (lines.length >= maxLines) return Added(this);
    return Added(_with(lines: [...lines, line], store: lineStore));
  }

  /// Vacía la bolsa y agrega [line] del nuevo negocio (tras confirmar).
  Cart replaceWith(CartLine line, CartStore lineStore) => Cart(store: lineStore, lines: [line]);

  Cart setNote(String note) => Cart(store: store, lines: lines, coupon: coupon, note: note.trim());

  Cart setQuantity(String lineId, Quantity quantity) =>
      _with(lines: lines.map((l) => l.id == lineId ? l.copyWith(quantity: quantity) : l).toList());

  Cart setNotes(String lineId, String notes) =>
      _with(lines: lines.map((l) => l.id == lineId ? l.copyWith(notes: notes) : l).toList());

  Cart remove(String lineId) {
    final remaining = lines.where((l) => l.id != lineId).toList();
    return remaining.isEmpty ? Cart.empty : _with(lines: remaining);
  }

  /// Reinserta una línea eliminada en su posición (para "Deshacer").
  Cart restore(CartLine line, int index, CartStore lineStore) {
    if (store != null && store!.id != lineStore.id) return this;
    final next = [...lines]..insert(index.clamp(0, lines.length), line);
    return _with(lines: next, store: lineStore);
  }

  Cart applyCoupon(Coupon coupon) => Cart(store: store, lines: lines, coupon: coupon, note: note);

  Cart removeCoupon() => Cart(store: store, lines: lines, note: note);

  Cart _with({required List<CartLine> lines, CartStore? store}) =>
      Cart(store: store ?? this.store, lines: lines, coupon: coupon, note: note);

  @override
  List<Object?> get props => [store, lines, coupon, note];
}
