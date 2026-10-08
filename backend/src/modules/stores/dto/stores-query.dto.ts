import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { LocationQueryDto } from '../../../common/dto/location-query.dto';
import { STORE_FILTERS, type StoreFilter } from '../store-filters';

export const STORE_SORTS = ['distance', 'popular', 'rating'] as const;
export type StoreSort = (typeof STORE_SORTS)[number];

export class StoresQueryDto extends LocationQueryDto {
  @IsOptional()
  @IsIn(STORE_SORTS)
  sort: StoreSort = 'distance';

  @IsOptional()
  @IsString()
  categoryId?: string;

  /** Filtros rápidos separados por coma: `open_now,free_delivery,top_rated,no_minimum,offers`. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string'
      ? value
          .split(',')
          .map((v) => v.trim())
          .filter(Boolean)
      : value,
  )
  @IsIn(STORE_FILTERS, { each: true, message: 'Filtro de negocios desconocido.' })
  filters: StoreFilter[] = [];

  /** Los abiertos primero, conservando el orden pedido dentro de cada grupo. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => value === true || value === 'true')
  @IsBoolean()
  openFirst = false;

  /** Por defecto solo se listan negocios que entregan en la ubicación. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => value === true || value === 'true')
  @IsBoolean()
  includeOutOfCoverage = false;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit = 20;
}
