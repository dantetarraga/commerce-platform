import { Transform } from 'class-transformer';
import { IsIn, IsOptional, IsString, Length, MaxLength } from 'class-validator';
import { OrderStatus } from '../../../generated/prisma/enums';
import { ListOrdersQueryDto } from './order-queries.dto';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export class CancelOrderDto {
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(300)
  reason?: string | null;
}

/** El negocio siempre explica por qué cancela: el cliente lo ve. */
export class StaffCancelOrderDto {
  @Transform(trim)
  @IsString()
  @Length(3, 300, { message: 'Cuéntale al cliente por qué se cancela.' })
  reason!: string;
}

export class AdvanceOrderDto {
  @IsIn(Object.values(OrderStatus))
  status!: OrderStatus;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(300)
  note?: string | null;
}

export class StaffOrdersQueryDto extends ListOrdersQueryDto {
  @IsOptional()
  @IsIn(Object.values(OrderStatus))
  status?: OrderStatus;
}
