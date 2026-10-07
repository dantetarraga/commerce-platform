import 'package:chaski/shared/partner/alarm/order_alarm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_alarm_controller.g.dart';

/// Qué hacer con la alarma después de ver la lista de pedidos.
enum OrderAlarmAction { ring, silence, keep }

/// Cuándo suena la alarma de una pantalla de trabajo, según sus pedidos.
final class OrderAlarmRule<T> {
  /// Negocio: suena mientras algún pedido espere respuesta según [pending]
  /// (p. ej. `o.status == OrderStatus.received`) y calla cuando ninguno.
  const OrderAlarmRule.whilePending(bool Function(T order) pending) : _pending = pending, _id = null;

  /// Repartidor: suena cuando aparece un pedido cuyo [id] no se había visto y
  /// calla cuando no queda ninguno. Lo visto se recorta a la lista actual: un
  /// pedido que se fue y vuelve suena de nuevo.
  const OrderAlarmRule.onNew(String Function(T order) id) : _id = id, _pending = null;

  final bool Function(T order)? _pending;
  final String Function(T order)? _id;

  /// Decide con [orders] y actualiza [seen] (ids ya avisados).
  OrderAlarmAction decide(List<T> orders, Set<String> seen) {
    if (_pending case final pending?) {
      return orders.any(pending) ? OrderAlarmAction.ring : OrderAlarmAction.silence;
    }
    final ids = orders.map(_id!).toSet();
    final fresh = ids.any((id) => !seen.contains(id));
    seen
      ..retainAll(ids)
      ..addAll(ids);
    if (ids.isEmpty) return OrderAlarmAction.silence;
    return fresh ? OrderAlarmAction.ring : OrderAlarmAction.keep;
  }
}

/// Maneja la [OrderAlarm] de una pantalla de trabajo; lo normal es usarlo a
/// través de [OrderAlarmScope].
class OrderAlarmController {
  OrderAlarmController(this._alarm);

  final OrderAlarm _alarm;
  final _seen = <String>{};
  bool? _awake;
  var _ringing = false;

  bool get isRinging => _ringing;

  /// Aplica [rule] a la lista actual de pedidos.
  void sync<T>(List<T> orders, OrderAlarmRule<T> rule) {
    switch (rule.decide(orders, _seen)) {
      case OrderAlarmAction.ring:
        _ringing = true;
        _alarm.ring().ignore();
      case OrderAlarmAction.silence:
        _ringing = false;
        _alarm.silence().ignore();
      case OrderAlarmAction.keep:
        break;
    }
  }

  /// Pantalla siempre encendida mientras se trabaja; solo llama a la alarma si cambia.
  void keepAwake({required bool on}) {
    if (_awake == on) return;
    _awake = on;
    _alarm.keepAwake(on: on).ignore();
  }

  /// Al salir de la pantalla: calla, apaga el "siempre encendida" y olvida lo
  /// visto (al volver, los pedidos pendientes suenan otra vez).
  void release() {
    _ringing = false;
    _alarm.silence().ignore();
    if (_awake ?? false) _alarm.keepAwake(on: false).ignore();
    _awake = null;
    _seen.clear();
  }
}

@Riverpod(keepAlive: true)
OrderAlarmController orderAlarmController(Ref ref) {
  final controller = OrderAlarmController(ref.watch(orderAlarmProvider));
  ref.onDispose(controller.release);
  return controller;
}

/// Pone la alarma de pedidos alrededor de una pantalla de trabajo: escucha [orders]
/// desde que se monta (sin efectos en `build`) y al desmontarse calla todo.
class OrderAlarmScope<T> extends ConsumerStatefulWidget {
  const OrderAlarmScope({required this.orders, required this.rule, required this.child, this.keepAwake = true, super.key});

  final ProviderListenable<AsyncValue<List<T>>> orders;
  final OrderAlarmRule<T> rule;

  /// Pantalla siempre encendida (negocio abierto, repartidor conectado).
  final bool keepAwake;
  final Widget child;

  @override
  ConsumerState<OrderAlarmScope<T>> createState() => _OrderAlarmScopeState<T>();
}

class _OrderAlarmScopeState<T> extends ConsumerState<OrderAlarmScope<T>> {
  late final OrderAlarmController _alarm = ref.read(orderAlarmControllerProvider);
  ProviderSubscription<AsyncValue<List<T>>>? _subscription;

  @override
  void initState() {
    super.initState();
    _alarm.keepAwake(on: widget.keepAwake);
    _listen();
  }

  void _listen() {
    _subscription?.close();
    _subscription = ref.listenManual(widget.orders, (_, next) {
      if (next.value case final orders?) _alarm.sync(orders, widget.rule);
    }, fireImmediately: true);
  }

  @override
  void didUpdateWidget(OrderAlarmScope<T> old) {
    super.didUpdateWidget(old);
    if (old.keepAwake != widget.keepAwake) _alarm.keepAwake(on: widget.keepAwake);
    if (old.orders != widget.orders) _listen();
  }

  @override
  void dispose() {
    _subscription?.close();
    _alarm.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
