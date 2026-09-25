import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

/** `?cursor=&limit=` para listas cronológicas (pedidos, avisos) → `{ items, nextCursor }`. */
export class CursorQueryDto {
  /** `nextCursor` de la página anterior. */
  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit = 20;
}
