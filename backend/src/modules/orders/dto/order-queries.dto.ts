import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';
import { CursorQueryDto } from '../../../common/dto/cursor-query.dto';

export class RateOrderDto {
  @IsInt()
  @Min(1, { message: 'Elige de 1 a 5 estrellas.' })
  @Max(5, { message: 'Elige de 1 a 5 estrellas.' })
  rating!: number;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(500)
  comment?: string | null;
}

export const CUSTOMER_ORDER_SCOPES = ['active', 'past'] as const;
export type CustomerOrderScope = (typeof CUSTOMER_ORDER_SCOPES)[number];

/** `?scope=active|past`: en curso o terminados (entregados y cancelados). Sin scope, todos. */
export class CustomerOrdersQueryDto extends CursorQueryDto {
  @IsOptional()
  @IsIn(CUSTOMER_ORDER_SCOPES, { message: 'El scope debe ser active o past.' })
  scope?: CustomerOrderScope;
}
