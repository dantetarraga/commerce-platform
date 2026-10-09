import 'package:apamuy/core/errors/failure_mapper.dart';
import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/core/network/api_client.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/checkout/domain/delivery_slots.dart';
import 'package:apamuy/features/checkout/infrastructure/models/delivery_slots_dto.dart';

/// `GET /stores/:id/delivery-slots`.
abstract interface class DeliverySlotsRemoteDataSource {
  Future<DeliverySlotsDto> forStore(String storeId);
}

class ApiDeliverySlotsRemoteDataSource implements DeliverySlotsRemoteDataSource {
  const ApiDeliverySlotsRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<DeliverySlotsDto> forStore(String storeId) async =>
      DeliverySlotsDto.fromJson(await _api.get('/stores/$storeId/delivery-slots') as Map<String, dynamic>);
}

/// Modo demo: la misma regla del backend sobre el horario del negocio en los fixtures.
class FakeDeliverySlotsRemoteDataSource implements DeliverySlotsRemoteDataSource {
  FakeDeliverySlotsRemoteDataSource(this._backend, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final FakeBackend _backend;
  final DateTime Function() _now;

  static const _leadMinutes = 45;
  static const _days = 3;

  @override
  Future<DeliverySlotsDto> forStore(String storeId) async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    final store = (catalog['stores'] as List).cast<Map<String, dynamic>>().firstWhere((s) => s['id'] == storeId);
    final hours = (store['schedules'] as List).cast<Map<String, dynamic>>();
    final now = _now();
    final earliest = now.add(const Duration(minutes: _leadMinutes));
    bool isOpen(DateTime at) {
      final minutes = at.hour * 60 + at.minute;
      final day = at.weekday % 7;
      return hours.any((h) {
        final (dow, opens, closes) = (h['dayOfWeek'] as int, h['opensAt'] as int, h['closesAt'] as int);
        if (closes > opens) return day == dow && minutes >= opens && minutes < closes;
        return (day == dow && minutes >= opens) || (day == (dow + 1) % 7 && minutes < closes);
      });
    }

    return DeliverySlotsDto(
      days: [
        for (var d = 0; d < _days; d++)
          DeliveryDayDto(
            date: _isoDate(DateTime(now.year, now.month, now.day + d)),
            slots: [
              for (var m = 0; m < 24 * 60; m += 15)
                if (DateTime(now.year, now.month, now.day + d, 0, m) case final at when !at.isBefore(earliest) && isOpen(at))
                  at.toUtc().toIso8601String(),
            ],
          ),
      ],
    );
  }

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class ApiDeliverySlotsRepository implements DeliverySlotsRepository {
  const ApiDeliverySlotsRepository(this._remote);

  final DeliverySlotsRemoteDataSource _remote;

  @override
  Future<Result<List<DeliveryDay>>> forStore(String storeId) =>
      guard(() async => (await _remote.forStore(storeId)).toEntities());
}
