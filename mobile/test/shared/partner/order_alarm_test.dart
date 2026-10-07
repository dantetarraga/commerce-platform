import 'package:chaski/shared/partner/alarm/order_alarm.dart';
import 'package:chaski/shared/partner/alarm/order_alarm_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _Alarm implements OrderAlarm {
  final calls = <String>[];

  @override
  Future<void> ring() async => calls.add('ring');

  @override
  Future<void> silence() async => calls.add('silence');

  @override
  Future<void> keepAwake({required bool on}) async => calls.add('awake:$on');
}

void main() {
  test('negocio: suena mientras haya pedidos sin responder', () {
    final alarm = _Alarm();
    final controller = OrderAlarmController(alarm);
    final rule = OrderAlarmRule<String>.whilePending((status) => status == 'received');
    controller.sync(['received', 'preparing'], rule);
    expect(controller.isRinging, isTrue);
    controller.sync(['preparing'], rule);
    expect(controller.isRinging, isFalse);
    expect(alarm.calls, ['ring', 'silence']);
  });

  test('repartidor: suena con ids nuevos y lo visto se recorta a la lista actual', () {
    final alarm = _Alarm();
    final controller = OrderAlarmController(alarm);
    final rule = OrderAlarmRule<String>.onNew((id) => id);
    controller
      ..sync(['a'], rule)
      ..sync(['a'], rule) // ya visto: no vuelve a sonar
      ..sync(['b'], rule) // nuevo
      ..sync(<String>[], rule) // no queda ninguno
      ..sync(['a'], rule); // se fue y volvió: suena otra vez
    expect(alarm.calls, ['ring', 'ring', 'silence', 'ring']);
  });

  test('pantalla encendida sin llamadas repetidas y apagada al salir', () {
    final alarm = _Alarm();
    OrderAlarmController(alarm)
      ..keepAwake(on: true)
      ..keepAwake(on: true)
      ..release();
    expect(alarm.calls, ['awake:true', 'silence', 'awake:false']);
  });
}
