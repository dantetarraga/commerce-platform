import { Transform } from 'class-transformer';
import { ArrayUnique, IsArray, IsIn, IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';
import { PhoneDto } from '../../auth/dto/auth.dto';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export const VEHICLE_TYPES = ['MOTO', 'BICI', 'AUTO'] as const;
export const PARTNER_ROLES = ['MERCHANT', 'COURIER'] as const;
export type PartnerRole = (typeof PARTNER_ROLES)[number];

export class FindUserQueryDto extends PhoneDto {}

/** El nombre solo se usa si el celular todavía no tiene cuenta. */
class NewPartnerDto extends PhoneDto {
  @Transform(trim)
  @IsString()
  @Length(1, 60, { message: 'Escribe el nombre.' })
  firstName!: string;

  @Transform(trim)
  @IsString()
  @Length(1, 60, { message: 'Escribe el apellido.' })
  lastName!: string;
}

export class CreateMerchantDto extends NewPartnerDto {
  /** Negocios que pasan a ser suyos; mientras no haya CRUD de catálogo salen del seed. */
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  storeIds?: string[];
}

export class CreateCourierDto extends NewPartnerDto {
  @IsString()
  cityId!: string;

  @IsIn(VEHICLE_TYPES, { message: 'El vehículo es MOTO, BICI o AUTO.' })
  vehicleType!: (typeof VEHICLE_TYPES)[number];

  /** Lo que ve el cliente: "Moto roja". */
  @Transform(trim)
  @IsString()
  @Length(1, 40, { message: 'Describe el vehículo (ej.: Moto roja).' })
  vehicleLabel!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 12)
  plate?: string;

  @IsOptional()
  @IsInt()
  @Min(1980)
  @Max(2100)
  activeSince?: number;
}

export class SuspendPartnerDto {
  /** Sin `roles` se quitan los dos. */
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsIn(PARTNER_ROLES, { each: true, message: 'Los roles de socio son MERCHANT y COURIER.' })
  roles?: PartnerRole[];
}
