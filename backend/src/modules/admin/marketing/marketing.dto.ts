import { OmitType, PartialType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsDate,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  Length,
  Matches,
  Max,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { MoneyDto } from '../../../common/dto/money.dto';
import { CouponType } from '../../../generated/prisma/enums';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);
const isSet = (_: object, value: unknown) => value !== null && value !== undefined;

export class CityQueryDto {
  @IsOptional()
  @IsString()
  cityId?: string;
}

export class CouponDto {
  /** Se guarda en mayúsculas y no se cambia después. */
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
  @Matches(/^[A-Z0-9]{3,20}$/, { message: 'El código va con 3 a 20 letras o números, sin espacios.' })
  code!: string;

  /** Lo que ve el cliente: "S/ 5 de bienvenida". */
  @Transform(trim)
  @IsString()
  @Length(3, 60)
  label!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(0, 200)
  description?: string;

  @IsEnum(CouponType, { message: 'El tipo es PERCENTAGE, FIXED_AMOUNT o FREE_DELIVERY.' })
  type!: CouponType;

  /** Solo `PERCENTAGE`. */
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  percentOff?: number;

  /** Solo `FIXED_AMOUNT`. */
  @IsOptional()
  @ValidateNested()
  @Type(() => MoneyDto)
  amountOff?: MoneyDto;

  /** Tope de un cupón de porcentaje; `null` lo quita. */
  @ValidateIf(isSet)
  @ValidateNested()
  @Type(() => MoneyDto)
  maxDiscount?: MoneyDto | null;

  @IsOptional()
  @ValidateNested()
  @Type(() => MoneyDto)
  minOrderAmount?: MoneyDto;

  /** Sin ciudad, vale en todas. */
  @ValidateIf(isSet)
  @IsString()
  cityId?: string | null;

  /** Sin negocio, vale en todos. */
  @ValidateIf(isSet)
  @IsString()
  storeId?: string | null;

  @Type(() => Date)
  @IsDate({ message: 'Fecha inválida (ISO 8601).' })
  startsAt!: Date;

  @Type(() => Date)
  @IsDate({ message: 'Fecha inválida (ISO 8601).' })
  endsAt!: Date;

  /** Usos en total; `null` = sin límite. */
  @ValidateIf(isSet)
  @IsInt()
  @Min(1)
  usageLimit?: number | null;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  perUserLimit?: number;

  @IsOptional()
  @IsBoolean()
  firstOrderOnly?: boolean;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

/** El código no cambia: los pedidos y banners lo referencian. */
export class UpdateCouponDto extends PartialType(OmitType(CouponDto, ['code'] as const)) {}

export class PromotionDto {
  @IsString()
  cityId!: string;

  /** Al tocar el banner se abre este negocio. */
  @ValidateIf(isSet)
  @IsString()
  storeId?: string | null;

  /** El banner muestra este cupón. */
  @ValidateIf(isSet)
  @IsString()
  couponId?: string | null;

  @Transform(trim)
  @IsString()
  @Length(3, 60)
  title!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(0, 120)
  subtitle?: string;

  @IsUrl({ protocols: ['https'], require_protocol: true }, { message: 'La imagen debe ser una URL https.' })
  imageUrl!: string;

  @Type(() => Date)
  @IsDate({ message: 'Fecha inválida (ISO 8601).' })
  startsAt!: Date;

  @Type(() => Date)
  @IsDate({ message: 'Fecha inválida (ISO 8601).' })
  endsAt!: Date;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdatePromotionDto extends PartialType(PromotionDto) {}
