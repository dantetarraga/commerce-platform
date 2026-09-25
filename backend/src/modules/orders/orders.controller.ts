import { Body, Controller, Get, Headers, HttpCode, HttpStatus, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../../common/decorators/auth.decorators';
import type { AuthUser } from '../../common/decorators/auth.decorators';
import { CursorQueryDto } from '../../common/dto/cursor-query.dto';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';
import { Role } from '../../generated/prisma/enums';
import { RateOrderDto } from './dto/order-queries.dto';
import { CancelOrderDto } from './dto/order-status.dto';
import { PlaceOrderDto } from './dto/place-order.dto';
import { toOrderResponse } from './order-presenter';
import { OrdersService } from './orders.service';
import { OrderStatusService } from './status/order-status.service';

const IDEMPOTENCY_KEY = /^[\w-]{8,100}$/;

@ApiTags('orders')
@ApiBearerAuth()
@Roles(Role.CUSTOMER)
@Controller('orders')
export class OrdersController {
  constructor(
    private readonly orders: OrdersService,
    private readonly status: OrderStatusService,
  ) {}

  @Post()
  @ApiHeader({ name: 'Idempotency-Key', required: false, description: 'Repetir la request devuelve el mismo pedido' })
  place(
    @CurrentUser() user: AuthUser,
    @Body() dto: PlaceOrderDto,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    if (idempotencyKey !== undefined && !IDEMPOTENCY_KEY.test(idempotencyKey)) {
      throw new AppException(ErrorCode.VALIDATION_ERROR, HttpStatus.BAD_REQUEST, 'Idempotency-Key inválida.', {
        fields: { 'Idempotency-Key': 'Entre 8 y 100 caracteres: letras, números, - o _.' },
      });
    }
    return this.orders.place(user.id, dto, idempotencyKey);
  }

  @Get()
  list(@CurrentUser() user: AuthUser, @Query() query: CursorQueryDto) {
    return this.orders.list(user.id, query);
  }

  @Get(':id')
  detail(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.orders.detail(user.id, id);
  }

  /** Solo mientras el negocio no empezó a prepararlo. */
  @Post(':id/cancel')
  @HttpCode(HttpStatus.OK)
  async cancel(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: CancelOrderDto) {
    const order = await this.status.cancel({ userId: user.id, role: Role.CUSTOMER }, id, dto.reason ?? undefined);
    return toOrderResponse(order);
  }

  @Post(':id/rating')
  @HttpCode(HttpStatus.OK)
  rate(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: RateOrderDto) {
    return this.orders.rate(user.id, id, dto);
  }
}
