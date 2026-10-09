import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/features/checkout/infrastructure/delivery_slots_remote_data_source.dart';
import 'package:apamuy/features/checkout/infrastructure/models/delivery_slots_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el JSON del backend se lee en la hora del teléfono', () {
    final days = DeliverySlotsDto.fromJson({
      'days': [
        {
          'date': '2026-10-10',
          'slots': ['2026-10-10T17:00:00.000Z'],
        },
        {'date': '2026-10-11', 'slots': <String>[]},
      ],
    }).toEntities();
    expect(days.first.date, DateTime(2026, 10, 10));
    expect(days.first.slots.single, DateTime.utc(2026, 10, 10, 17).toLocal());
    expect(days.last.isClosed, isTrue);
  });

  test('el modo demo sigue el horario del negocio, cada 15 min y desde 45 min después', () async {
    // Viernes 9 de octubre, 10:00. En los fixtures abre de 11:00 a 24:00 los viernes.
    final stores = (await FakeBackend(latency: Duration.zero).catalog())['stores'] as List<dynamic>;
    final store = stores.first as Map<String, dynamic>;
    final source = FakeDeliverySlotsRemoteDataSource(FakeBackend(latency: Duration.zero), now: () => DateTime(2026, 10, 9, 10));
    final days = (await source.forStore(store['id'] as String)).toEntities();
    expect(days, hasLength(3));
    final today = days.first.slots;
    expect(today.first, DateTime(2026, 10, 9, 11));
    expect(today.last, DateTime(2026, 10, 9, 23, 45));
    expect(today.every((at) => at.minute % 15 == 0), isTrue);
  });
}
