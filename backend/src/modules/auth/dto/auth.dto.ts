import { Transform } from 'class-transformer';
import { IsString, Length, Matches } from 'class-validator';

const stripSeparators = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.replace(/[\s-]/g, '') : value;
const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

class PhoneDto {
  /** Celular peruano: 9 dígitos que empiezan con 9. */
  @Transform(stripSeparators)
  @IsString()
  @Matches(/^9\d{8}$/, { message: 'Ingresa un celular de 9 dígitos que empiece con 9.' })
  phone!: string;
}

export class RequestOtpDto extends PhoneDto {}

export class VerifyOtpDto extends PhoneDto {
  @IsString()
  @Matches(/^\d{6}$/, { message: 'El código tiene 6 dígitos.' })
  code!: string;
}

export class RegisterDto {
  @IsString()
  registrationToken!: string;

  @Transform(trim)
  @IsString()
  @Length(1, 60, { message: 'Escribe tu nombre.' })
  firstName!: string;

  @Transform(trim)
  @IsString()
  @Length(1, 60, { message: 'Escribe tu apellido.' })
  lastName!: string;
}

export class RefreshTokenDto {
  @IsString()
  @Length(1, 200)
  refreshToken!: string;
}
