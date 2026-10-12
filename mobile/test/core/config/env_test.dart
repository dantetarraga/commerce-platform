import 'package:apamuy/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un release contra la API pide https; la demo y debug no', () {
    const local = AppEnv(apiBaseUrl: 'http://10.0.2.2:3000/api/v1', useFakeData: false);
    const prod = AppEnv(apiBaseUrl: 'https://api.apamuy.pe/api/v1', useFakeData: false);
    const demo = AppEnv(apiBaseUrl: 'http://localhost:3000/api/v1', useFakeData: true);

    expect(local.releaseProblem(release: true), contains('https'));
    expect(local.releaseProblem(), isNull); // en debug no aplica
    expect(prod.releaseProblem(release: true), isNull);
    expect(demo.releaseProblem(release: true), isNull);
  });
}
