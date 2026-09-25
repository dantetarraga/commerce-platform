import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../../common/decorators/auth.decorators';
import type { AuthUser } from '../../common/decorators/auth.decorators';
import { CursorQueryDto } from '../../common/dto/cursor-query.dto';
import { OrderStatus, Role } from '../../generated/prisma/enums';
import { AdvanceOrderDto } from '../orders/dto/order-status.dto';
import { toStaffOrderResponse } from '../orders/order-presenter';
import { OrdersService } from '../orders/orders.service';
import { OrderStatusService, scopeFor } from '../orders/status/order-status.service';

/**
 * Operación del repartidor: pedidos listos para tomar en su ciudad, sus
 * pedidos, tomar uno, salir a entregarlo y marcarlo entregado.
 */
@ApiTags('courier')
@ApiBearerAuth()
@Roles(Role.COURIER)
@Controller('courier')
export class CouriersController {
  constructor(
    private readonly orders: OrdersService,
    private readonly status: OrderStatusService,
  ) {}

  /** Listos en el negocio y sin repartidor, en la ciudad del courier. */
  @Get('orders/available')
  async available(@CurrentUser() user: AuthUser, @Query() query: CursorQueryDto) {
    const courier = await this.status.courierFor(user.id);
    const { orders, nextCursor } = await this.orders.page(
      { cityId: courier.cityId, status: OrderStatus.READY, courierId: null },
      query,
    );
    return { items: orders.map(toStaffOrderResponse), nextCursor };
  }

  /** Los pedidos que tomó, del más reciente al más antiguo. */
  @Get('orders')
  async mine(@CurrentUser() user: AuthUser, @Query() query: CursorQueryDto) {
    const { orders, nextCursor } = await this.orders.page(scopeFor({ userId: user.id, role: Role.COURIER }), query);
    return { items: orders.map(toStaffOrderResponse), nextCursor };
  }

  @Post('orders/:id/accept')
  @HttpCode(HttpStatus.OK)
  async accept(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return toStaffOrderResponse(await this.status.accept(user.id, id));
  }

  /** `status` = ON_THE_WAY o DELIVERED. */
  @Post('orders/:id/status')
  @HttpCode(HttpStatus.OK)
  async advance(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: AdvanceOrderDto) {
    const actor = { userId: user.id, role: Role.COURIER };
    return toStaffOrderResponse(await this.status.advance(actor, id, dto.status, dto.note ?? undefined));
  }
}
