import { Transform } from 'class-transformer';
import { IsEmail, IsOptional, IsString, IsUrl, Length, ValidateIf } from 'class-validator';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);
const trimLower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim().toLowerCase() : value);

/** El celular no se cambia aquí: requiere verificar el número nuevo. */
export class UpdateMeDto {
  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 60, { message: 'Escribe tu nombre.' })
  firstName?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 60, { message: 'Escribe tu apellido.' })
  lastName?: string;

  /** `null` borra el correo. */
  @ValidateIf((_, value) => value !== null && value !== undefined)
  @Transform(trimLower)
  @IsEmail({}, { message: 'Ese correo no parece válido.' })
  email?: string | null;

  @ValidateIf((_, value) => value !== null && value !== undefined)
  @IsUrl({ protocols: ['https'], require_protocol: true }, { message: 'La foto debe ser una URL https.' })
  avatarUrl?: string | null;
}
