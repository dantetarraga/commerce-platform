import { Transform } from 'class-transformer';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export const PRODUCT_STATUSES = ['all', 'available', 'sold_out'] as const;
export type ProductStatusFilter = (typeof PRODUCT_STATUSES)[number];

/** `?status=all|available|sold_out&q=` para la carta del negocio. */
export class MerchantProductsQueryDto {
  @IsOptional()
  @IsIn(PRODUCT_STATUSES, { message: 'El filtro debe ser all, available o sold_out.' })
  status: ProductStatusFilter = 'all';

  /** Busca en el nombre, sin importar tildes ni mayúsculas. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(60, { message: 'La búsqueda es demasiado larga.' })
  q?: string;
}
