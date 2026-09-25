import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsISO8601,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  Length,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { MoneyDto } from '../../../common/dto/money.dto';
import { PaymentMethodType } from '../../../generated/prisma/enums';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

/** Propina máxima: S/ 50. */
export const MAX_TIP = 5000;

// Cuerpo de `POST /orders` tal como lo arma la app (`OrderJson.requestToJson`).
// Los precios no vienen del cliente: solo IDs y cantidades.

export class PlaceOrderItemDto {
  @IsString()
  productId!: string;

  @IsOptional()
  @IsString()
  variantId?: string | null;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(30)
  optionValueIds: string[] = [];

  @IsInt()
  @Min(1)
  @Max(99, { message: 'Máximo 99 unidades por producto.' })
  quantity!: number;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(200)
  notes?: string | null;
}

export class OrderAddressDto {
  @Transform(trim)
  @IsString()
  @Length(1, 40, { message: 'Ponle un nombre a la dirección.' })
  title!: string;

  @Transform(trim)
  @IsString()
  @Length(1, 160, { message: 'Escribe la dirección.' })
  street!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(160)
  reference?: string | null;

  @IsLatitude({ message: 'Latitud inválida.' })
  latitude!: number;

  @IsLongitude({ message: 'Longitud inválida.' })
  longitude!: number;
}

export class OrderPaymentDto {
  @IsIn(Object.values(PaymentMethodType), { message: 'Elige cómo vas a pagar.' })
  type!: PaymentMethodType;

  /** Solo efectivo: "¿con cuánto pagas?". */
  @IsOptional()
  @ValidateNested()
  @Type(() => MoneyDto)
  changeFor?: MoneyDto | null;
}

export class PlaceOrderDto {
  @IsString()
  storeId!: string;

  @IsArray()
  @ArrayMinSize(1, { message: 'Tu bolsa está vacía.' })
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => PlaceOrderItemDto)
  items!: PlaceOrderItemDto[];

  @ValidateNested()
  @Type(() => OrderAddressDto)
  address!: OrderAddressDto;

  @ValidateNested()
  @Type(() => OrderPaymentDto)
  payment!: OrderPaymentDto;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(40)
  couponCode?: string | null;

  @IsOptional()
  @IsISO8601({ strict: true }, { message: 'Fecha programada inválida.' })
  scheduledFor?: string | null;

  @IsOptional()
  @ValidateNested()
  @Type(() => MoneyDto)
  tip?: MoneyDto | null;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(300)
  notes?: string | null;
}
