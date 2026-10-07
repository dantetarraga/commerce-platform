import { PartialType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsInt,
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

/** Con `id` se edita ese elemento; sin `id` se crea; los que no vengan se borran. */
class ChildDto {
  @IsOptional()
  @IsString()
  id?: string;

  @Transform(trim)
  @IsString()
  @Length(1, 60)
  name!: string;

  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}

/** "Medio pollo", "1/4": cada variante tiene su precio. */
export class VariantDto extends ChildDto {
  @ValidateNested()
  @Type(() => MoneyDto)
  price!: MoneyDto;
}

export class OptionValueDto extends ChildDto {
  /** Lo que suma al precio; sin valor, nada. */
  @IsOptional()
  @ValidateNested()
  @Type(() => MoneyDto)
  priceDelta?: MoneyDto;
}

/** Grupo de opciones: "Cremas" (0 a 3), "Bebida" (elige 1). */
export class OptionDto {
  @IsOptional()
  @IsString()
  id?: string;

  @Transform(trim)
  @IsString()
  @Length(1, 60)
  name!: string;

  /** ≥ 1 lo vuelve obligatorio. */
  @IsInt()
  @Min(0)
  @Max(20)
  minSelect!: number;

  @IsInt()
  @Min(1)
  @Max(20)
  maxSelect!: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsArray()
  @ArrayMaxSize(30)
  @ValidateNested({ each: true })
  @Type(() => OptionValueDto)
  values!: OptionValueDto[];
}

export class ProductDto {
  /** `null` lo deja fuera de las secciones. */
  @IsOptional()
  @IsString()
  menuSectionId?: string | null;

  @Transform(trim)
  @IsString()
  @Length(2, 80, { message: 'Escribe el nombre del producto.' })
  name!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(0, 500)
  description?: string;

  @IsOptional()
  @IsUrl({ protocols: ['https'], require_protocol: true }, { message: 'La foto debe ser una URL https.' })
  imageUrl?: string;

  /** Si tiene variantes, manda el precio de cada variante. */
  @ValidateNested()
  @Type(() => MoneyDto)
  basePrice!: MoneyDto;

  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  /** `null` = no se controla stock. */
  @IsOptional()
  @IsInt()
  @Min(0)
  stock?: number | null;

  @IsOptional()
  @IsBoolean()
  isFeatured?: boolean;

  /** Hecho en la ciudad. */
  @IsOptional()
  @IsBoolean()
  isLocal?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => VariantDto)
  variants?: VariantDto[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => OptionDto)
  options?: OptionDto[];
}

/** Lo que no venga queda igual; `variants`/`options`, si vienen, reemplazan la lista. */
export class UpdateProductDto extends PartialType(ProductDto) {}
