import { OmitType, PartialType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  Length,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { MoneyDto } from '../../../common/dto/money.dto';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);
const https = { protocols: ['https'], require_protocol: true };

export class OpeningHoursDto {
  /** 0 = domingo … 6 = sábado. */
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek!: number;

  /** Minutos desde las 00:00 (hora local de la ciudad). */
  @IsInt()
  @Min(0)
  @Max(1439)
  opensAt!: number;

  /** 1440 = medianoche; si es menor que `opensAt`, el turno cruza la medianoche. */
  @IsInt()
  @Min(1)
  @Max(1440)
  closesAt!: number;
}

export class ReplaceSchedulesDto {
  @IsArray()
  @ArrayMaxSize(28)
  @ValidateNested({ each: true })
  @Type(() => OpeningHoursDto)
  schedules!: OpeningHoursDto[];
}

/** Un negocio nuevo queda en borrador (`isActive: false`) hasta publicarlo. */
export class CreateStoreDto {
  @IsString()
  cityId!: string;

  /** Usuario con rol de negocio (`POST admin/merchants`). */
  @IsString()
  ownerId!: string;

  @Transform(trim)
  @IsString()
  @Length(2, 80, { message: 'Escribe el nombre del negocio.' })
  name!: string;

  @Transform(trim)
  @IsString()
  @Length(3, 160, { message: 'Escribe la dirección del local.' })
  addressLine!: string;

  @IsLatitude({ message: 'Latitud inválida.' })
  latitude!: number;

  @IsLongitude({ message: 'Longitud inválida.' })
  longitude!: number;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(0, 500)
  description?: string;

  @IsOptional()
  @IsUrl(https, { message: 'El logo debe ser una URL https.' })
  logoUrl?: string;

  @IsOptional()
  @IsUrl(https, { message: 'La portada debe ser una URL https.' })
  coverUrl?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(6, 15)
  phone?: string;

  /** Sin valor, el máximo de la ciudad. */
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.5)
  @Max(30)
  deliveryRadiusKm?: number;

  @IsOptional()
  @ValidateNested()
  @Type(() => MoneyDto)
  minOrderAmount?: MoneyDto;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(180)
  avgPrepMinutes?: number;

  /** Momentos del día: desayuno, almuerzo, noche… */
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  tags?: string[];

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(0, 40)
  promoLabel?: string;

  /** "Don Julián": cómo se presenta el negocio. */
  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(0, 60)
  ownerDisplayName?: string;

  @IsOptional()
  @IsInt()
  @Min(1950)
  @Max(2100)
  attendingSince?: number;

  /** Reemplaza las categorías del negocio. */
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  categoryIds?: string[];

  /** Publicado en la app del cliente. */
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(28)
  @ValidateNested({ each: true })
  @Type(() => OpeningHoursDto)
  schedules?: OpeningHoursDto[];
}

/** El horario se cambia con `PUT admin/stores/:id/schedules`; la ciudad no cambia. */
export class UpdateStoreDto extends PartialType(OmitType(CreateStoreDto, ['cityId', 'schedules'] as const)) {}

export class StoresQueryDto {
  @IsOptional()
  @IsString()
  cityId?: string;
}

export class SectionDto {
  @Transform(trim)
  @IsString()
  @Length(1, 60, { message: 'Escribe el nombre de la sección.' })
  name!: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}

export class UpdateSectionDto extends PartialType(SectionDto) {}

export class CategoryDto {
  @Transform(trim)
  @IsString()
  @Length(2, 40, { message: 'Escribe el nombre de la categoría.' })
  name!: string;

  /** Sin slug, se arma con el nombre. */
  @IsOptional()
  @IsString()
  @Length(2, 40)
  slug?: string;

  @IsOptional()
  @IsUrl(https, { message: 'El ícono debe ser una URL https.' })
  iconUrl?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}

export class UpdateCategoryDto extends PartialType(CategoryDto) {}
