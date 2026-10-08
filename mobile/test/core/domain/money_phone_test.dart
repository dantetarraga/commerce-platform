import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/domain/phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Money.tryParse entiende lo que escribe la persona', () {
    expect(Money.tryParse('4'), const Money(400));
    expect(Money.tryParse('4,50'), const Money(450));
    expect(Money.tryParse(' S/ 12.5 '), const Money(1250));
    expect(Money.tryParse(''), isNull);
    expect(Money.tryParse('abc'), isNull);
    expect(Money.tryParse('-3'), isNull);
  });

  test('Money resta sin quedar en negativo', () {
    expect(const Money(500) - const Money(200), const Money(300));
    expect(() => const Money(100) - const Money(200), throwsArgumentError);
  });

  test('PhoneNumber se muestra de a tres dígitos', () {
    expect(PhoneNumber.trusted('984123456').display, '984 123 456');
    expect(PhoneNumber.displayOf('12345'), '12345');
  });
}
