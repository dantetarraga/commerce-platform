import { Transform, Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Length, Max, MaxLength, Min, ValidateNested } from 'class-validator';
import { CursorQueryDto } from '../../../common/dto/cursor-query.dto';
import { MoneyDto } from '../../../common/dto/money.dto';
import { OrderStatus, PaymentMethodType } from '../../../generated/prisma/enums';
import { ORDER_LIST_SCOPES } from '../order-list-scope';
import type { OrderListScope } from '../order-list-scope';

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

export class StaffOrdersQueryDto extends CursorQueryDto {
  @IsOptional()
  @IsIn(Object.values(OrderStatus))
  status?: OrderStatus;

  /** `active`: no finales; `today`: creados hoy (hora de Lima). */
  @IsOptional()
  @IsIn(ORDER_LIST_SCOPES)
  scope?: OrderListScope;
}

/** El negocio acepta y dice en cuántos minutos tendrá listo el pedido. */
export class AcceptOrderDto {
  @Type(() => Number)
  @IsInt({ message: 'El tiempo de preparación va en minutos.' })
  @Min(5, { message: 'El tiempo de preparación es de 5 a 90 minutos.' })
  @Max(90, { message: 'El tiempo de preparación es de 5 a 90 minutos.' })
  prepMinutes!: number;
}

/** Métodos que el repartidor puede registrar al cobrar (contraentrega). */
export const COLLECTED_METHODS = [PaymentMethodType.CASH, PaymentMethodType.YAPE, PaymentMethodType.PLIN];

/** ON_THE_WAY, o DELIVERED con cómo pagó el cliente y cuánto cobró. */
export class CourierAdvanceOrderDto extends AdvanceOrderDto {
  @IsOptional()
  @IsIn(COLLECTED_METHODS, { message: 'Elige cómo pagó el cliente: efectivo, Yape o Plin.' })
  collectedMethod?: PaymentMethodType;

  @IsOptional()
  @ValidateNested()
  @Type(() => MoneyDto)
  collectedAmount?: MoneyDto;
}

export class CourierOrdersQueryDto extends CursorQueryDto {
  /** `active`: en curso; `today`: creados hoy (hora de Lima). */
  @IsOptional()
  @IsIn(ORDER_LIST_SCOPES)
  scope?: OrderListScope;
}
