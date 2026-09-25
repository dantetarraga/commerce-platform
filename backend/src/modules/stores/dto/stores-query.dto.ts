import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { LocationQueryDto } from '../../../common/dto/location-query.dto';

export const STORE_SORTS = ['distance', 'popular', 'rating'] as const;
export type StoreSort = (typeof STORE_SORTS)[number];

export class StoresQueryDto extends LocationQueryDto {
  @IsOptional()
  @IsIn(STORE_SORTS)
  sort: StoreSort = 'distance';

  @IsOptional()
  @IsString()
  categoryId?: string;

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
