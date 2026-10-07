import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/features/discovery/infrastructure/repositories/popular_searches_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lo más pedido cuenta los negocios reales del catálogo y omite los que nadie vende', () async {
    final result = await FakePopularSearchesRepository(FakeBackend(latency: Duration.zero)).popular();
    final popular = result.getOrThrow();
    expect(popular, isNotEmpty);
    for (final p in popular) {
      expect(p.storeCount, greaterThan(0));
    }
    expect(popular.map((p) => p.term), contains('Pollo a la brasa'));
  });
}
