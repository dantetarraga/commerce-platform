import { IsEnum, IsOptional, IsString, Matches } from 'class-validator';
import { CursorQueryDto } from '../../../common/dto/cursor-query.dto';
import { OrderStatus } from '../../../generated/prisma/enums';

export class AdminBoardQueryDto {
  /** Sin ciudad: todas. */
  @IsOptional()
  @IsString()
  cityId?: string;
}

export class AdminOrdersQueryDto extends CursorQueryDto {
  @IsOptional()
  @IsString()
  cityId?: string;

  @IsOptional()
  @IsEnum(OrderStatus)
  status?: OrderStatus;

  /** Día de creación en hora de Lima; sin fecha, hoy. */
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'La fecha va como AAAA-MM-DD.' })
  date?: string;

  /** Código del pedido (#2481) o celular del cliente. */
  @IsOptional()
  @IsString()
  q?: string;
}
