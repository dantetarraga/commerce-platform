import { PartialType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsInt, IsNumber, IsOptional, IsString, Length, Max, Min, ValidateNested } from 'class-validator';
import { MoneyDto } from '../../../common/dto/money.dto';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

/** Parámetros de reparto de una ciudad. Distancias en km; tarifas en céntimos. */
export class CityDto {
  @Transform(trim)
  @IsString()
  @Length(2, 60)
  name!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(0, 60)
  region?: string;

  @IsNumber({ maxDecimalPlaces: 6 })
  @Min(-90)
  @Max(90)
  centerLat!: number;

  @IsNumber({ maxDecimalPlaces: 6 })
  @Min(-180)
  @Max(180)
  centerLng!: number;

  /** Zona de reparto: radio alrededor del centro. */
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.5)
  @Max(50)
  coverageKm!: number;

  /** Lo más lejos que se reparte desde un negocio, medido por calle. */
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.5)
  @Max(50)
  maxDeliveryKm!: number;

  @ValidateNested()
  @Type(() => MoneyDto)
  baseDeliveryFee!: MoneyDto;

  /** Por cada km por calle, redondeado hacia arriba. */
  @ValidateNested()
  @Type(() => MoneyDto)
  feePerKm!: MoneyDto;

  /** Línea recta → distancia por calle (1.3 = 30 % más). */
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  @Max(3)
  routeFactor!: number;

  /** Velocidad media del repartidor, para el tiempo estimado. */
  @IsInt()
  @Min(5)
  @Max(80)
  avgSpeedKmh!: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

/** El slug y la moneda no se cambian: los usan las URLs y los precios guardados. */
export class UpdateCityDto extends PartialType(CityDto) {}
