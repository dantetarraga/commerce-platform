import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/core/storage/storage_providers.dart';
import 'package:chaski/features/addresses/addresses.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/checkout/domain/checkout.dart';
import 'package:chaski/features/checkout/infrastructure/checkout_preferences.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'checkout_controller.g.dart';

@Riverpod(keepAlive: true)
CheckoutPreferences checkoutPreferences(Ref ref) => CheckoutPreferences(ref.watch(localJsonStoreProvider));

final class CheckoutState extends Equatable {
  const CheckoutState({this.draft = const CheckoutDraft(), this.placing = false, this.error});

  final CheckoutDraft draft;
  final bool placing;
  final Failure? error;

  CheckoutState copyWith({CheckoutDraft? draft, bool? placing, Failure? error, bool clearError = false}) => CheckoutState(
    draft: draft ?? this.draft,
    placing: placing ?? this.placing,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [draft, placing, error];
}

@riverpod
class CheckoutController extends _$CheckoutController {
  @override
  CheckoutState build() {
    // Vive mientras dure la sesión: la hora programada se elige a veces en el
    // negocio (cerrado) antes de llegar al checkout.
    ref.keepAlive();
    // Precarga el último método de pago usado.
    ref.read(checkoutPreferencesProvider).lastPayment().then((kind) {
      if (kind != null && ref.mounted && state.draft.paymentKind == null) {
        state = state.copyWith(draft: state.draft.copyWith(paymentKind: kind));
      }
    }).ignore();
    return const CheckoutState();
  }

  void setDeliveryTime(DeliveryTime time) => state = state.copyWith(draft: state.draft.copyWith(deliveryTime: time), clearError: true);

  void setPayment(PaymentKind kind) => state = state.copyWith(
    draft: state.draft.copyWith(paymentKind: kind, clearChange: kind != PaymentKind.cash),
    clearError: true,
  );

  /// Propina para el repartidor (cero = sin propina).
  void setTip(Money tip) => state = state.copyWith(draft: state.draft.copyWith(tip: tip), clearError: true);

  /// `null` = paga con monto exacto.
  void setCashChange(Money? amount) => state = state.copyWith(
    draft: amount == null ? state.draft.copyWith(clearChange: true) : state.draft.copyWith(cashChangeFor: amount),
    clearError: true,
  );

  /// Confirma el pedido. Si sale bien vacía la bolsa, fija el pedido activo
  /// (la posta pasa a mostrarlo) y devuelve el pedido creado.
  Future<Order?> place() async {
    final cart = ref.read(cartControllerProvider).value ?? Cart.empty;
    final address = ref.read(selectedAddressProvider);
    // Una hora programada que ya pasó se vuelve "lo antes posible".
    final draft = switch (state.draft.deliveryTime) {
      DeliverAt(:final at) when !at.isAfter(DateTime.now()) => state.draft.copyWith(deliveryTime: const DeliverAsap()),
      _ => state.draft,
    };
    if (draft.issues(cart, address).isNotEmpty || address == null) return null;

    state = state.copyWith(placing: true, clearError: true);
    final result = await ref.read(ordersRepositoryProvider).placeOrder(draft.toRequest(cart, address));
    if (!ref.mounted) return null;
    switch (result) {
      case Ok(:final value):
        await ref.read(checkoutPreferencesProvider).rememberPayment(draft.paymentKind!);
        await ref.read(cartControllerProvider.notifier).clear();
        ref.read(activeOrderIdProvider.notifier).set(value.id);
        ref.invalidate(ordersHistoryProvider);
        // El siguiente pedido empieza "lo antes posible" y sin propina.
        if (ref.mounted) {
          state = state.copyWith(
            placing: false,
            draft: CheckoutDraft(paymentKind: draft.paymentKind, cashChangeFor: draft.cashChangeFor),
          );
        }
        return value;
      case Err(:final failure):
        state = state.copyWith(placing: false, error: failure);
        return null;
    }
  }
}
