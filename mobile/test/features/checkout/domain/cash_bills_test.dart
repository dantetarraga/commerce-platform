import 'package:chaski/core/domain/money.dart';
import 'package:chaski/features/checkout/domain/checkout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sugiere hasta tres billetes mayores que el total', () {
    expect(suggestedBills(const Money(1850)), const [Money(2000), Money(5000), Money(10000)]);
    expect(suggestedBills(const Money(6000)), const [Money(10000), Money(20000)]);
    expect(suggestedBills(const Money(2000)), const [Money(5000), Money(10000), Money(20000)]);
    expect(suggestedBills(const Money(30000)), isEmpty);
  });

  test('vuelto solo si el billete alcanza', () {
    expect(cashChange(const Money(5000), const Money(1850)), const Money(3150));
    expect(cashChange(const Money(1000), const Money(1850)), isNull);
    expect(cashChange(null, const Money(1850)), isNull);
  });
}
