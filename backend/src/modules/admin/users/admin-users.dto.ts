import { Transform, Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { PARTNER_ROLES, PartnerRole } from '../partners/partners.dto';

export const USER_ROLE_FILTERS = ['CUSTOMER', 'MERCHANT', 'COURIER', 'ADMIN'] as const;
export const USER_STATUS_FILTERS = ['active', 'blocked'] as const;

export class ListUsersQueryDto {
  /** Nombre o celular (desde el primer dígito). */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(60)
  q?: string;

  /** Con ese rol. CUSTOMER = solo clientes (sin rol de socio ni admin). */
  @IsOptional()
  @IsIn(USER_ROLE_FILTERS, { message: 'El rol es CUSTOMER, MERCHANT, COURIER o ADMIN.' })
  role?: (typeof USER_ROLE_FILTERS)[number];

  @IsOptional()
  @IsIn(USER_STATUS_FILTERS, { message: 'El estado es active o blocked.' })
  status?: (typeof USER_STATUS_FILTERS)[number];

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  pageSize?: number;
}

export class BlockUserDto {
  /** Por qué se bloquea; queda en el historial. */
  @IsOptional()
  @IsString()
  @MaxLength(200)
  reason?: string;
}

export class RestorePartnerDto {
  @IsArray()
  @ArrayNotEmpty({ message: 'Elige qué rol de socio devolver.' })
  @ArrayUnique()
  @IsIn(PARTNER_ROLES, { each: true, message: 'Los roles de socio son MERCHANT y COURIER.' })
  roles!: PartnerRole[];
}

export class SetAdminDto {
  @IsBoolean()
  isAdmin!: boolean;
}
