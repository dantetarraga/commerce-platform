import { Transform } from 'class-transformer';
import { IsOptional, IsString, MaxLength } from 'class-validator';

/** `?q=` para buscar en la carta de un negocio. Vacío: toda la carta. */
export class MenuSearchQueryDto {
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(80, { message: 'La búsqueda es demasiado larga.' })
  q?: string;
}
