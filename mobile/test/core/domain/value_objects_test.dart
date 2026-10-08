import 'package:apamuy/core/domain/email_address.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/domain/phone_number.dart';
import 'package:apamuy/core/domain/quantity.dart';
import 'package:apamuy/core/domain/value_failure.dart';
import 'package:apamuy/features/auth/domain/value_objects/otp_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('suma y multiplica en céntimos sin perder precisión', () {
      const price = Money(1990);
      expect(price + const Money(10), const Money(2000));
      expect(price * 3, const Money(5970));
    });

    test('no permite operar monedas distintas', () {
      expect(() => const Money(100) + const Money(100, currency: 'USD'), throwsArgumentError);
    });
  });

  group('EmailAddress', () {
    test('normaliza espacios y mayúsculas', () {
      expect(EmailAddress.create('  Cliente@Apamuy.PE ').valueOrNull?.value, 'cliente@apamuy.pe');
    });

    test('rechaza vacío y formato inválido', () {
      expect(EmailAddress.create('').failureOrNull, const EmptyValue());
      expect(EmailAddress.create('cliente@apamuy').failureOrNull, const InvalidEmail());
    });
  });

  group('PhoneNumber', () {
    test('acepta celulares peruanos con espacios o guiones', () {
      expect(PhoneNumber.create('984 123-456').valueOrNull?.value, '984123456');
    });

    test('rechaza números que no son celulares peruanos', () {
      expect(PhoneNumber.create('084123456').failureOrNull, const InvalidPhone());
      expect(PhoneNumber.create('98412345').failureOrNull, const InvalidPhone());
    });
  });

  group('OtpCode', () {
    test('exige exactamente 6 dígitos', () {
      expect(OtpCode.create('').failureOrNull, const EmptyValue());
      expect(OtpCode.create('12345').failureOrNull, const InvalidOtp());
      expect(OtpCode.create('12a456').failureOrNull, const InvalidOtp());
      expect(OtpCode.create('123 456').valueOrNull?.value, '123456');
    });
  });

  group('Quantity', () {
    test('no baja de 1 ni sube de 99', () {
      expect(Quantity.one.decrement(), Quantity.one);
      final max = Quantity.create(Quantity.max).valueOrNull!;
      expect(max.increment(), max);
      expect(Quantity.create(0).failureOrNull, const OutOfRange(Quantity.min, Quantity.max));
    });
  });
}
