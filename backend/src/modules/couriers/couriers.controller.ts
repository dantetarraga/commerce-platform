import { Body, Controller, Get, HttpCode, HttpStatus, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../../common/decorators/auth.decorators';
import type { AuthUser } from '../../common/decorators/auth.decorators';
import { CursorQueryDto } from '../../common/dto/cursor-query.dto';
import { DayQueryDto } from '../../common/dto/day-query.dto';
import { CourierStatus, OrderStatus, Role } from '../../generated/prisma/enums';
import { CourierAdvanceOrderDto, CourierOrdersQueryDto } from '../orders/dto/order-status.dto';
import { listScopeWhere } from '../orders/order-list-scope';
import { toStaffOrderResponse } from '../orders/order-presenter';
import { OrdersService } from '../orders/orders.service';
import { OrderStatusService, scopeFor } from '../orders/status/order-status.service';
import { CouriersService } from './couriers.service';
import { CourierLocationDto } from './dto/courier-location.dto';
import { UpdateCourierStatusDto } from './dto/update-courier-status.dto';

/**
 * Operación del repartidor (app Chaski Socios): conectarse, ver los pedidos
 * listos de su ciudad, tomar uno, salir a entregarlo, registrar el cobro al
 * entregar y ver el resumen del día.
 */
@ApiTags('courier')
@ApiBearerAuth()
@Roles(Role.COURIER)
@Controller('courier')
export class CouriersController {
  constructor(
    private readonly orders: OrdersService,
    private readonly status: OrderStatusService,
    private readonly couriers: CouriersService,
  ) {}

  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return this.couriers.me(user.id);
  }

  /** AVAILABLE u OFFLINE. Con un pedido en curso no puede desconectarse. */
  @Patch('me/status')
  setStatus(@CurrentUser() user: AuthUser, @Body() dto: UpdateCourierStatusDto) {
    return this.couriers.setStatus(user.id, dto.status);
  }

  /**
   * Última posición, cada ~10 s mientras lleva un pedido. Las que llegan con
   * menos de 2 s de diferencia se ignoran. Desconectado responde 409.
   */
  @Post('me/location')
  @HttpCode(HttpStatus.NO_CONTENT)
  async location(@CurrentUser() user: AuthUser, @Body() dto: CourierLocationDto) {
    await this.couriers.updateLocation(user.id, dto.lat, dto.lng);
  }

  /** Entregas y cobros del día (hora de Lima). */
  @Get('me/summary')
  summary(@CurrentUser() user: AuthUser, @Query() query: DayQueryDto) {
    return this.couriers.summary(user.id, query.date);
  }

  /** Listos en el negocio y sin repartidor, en la ciudad del courier. Vacío si no está AVAILABLE. */
  @Get('orders/available')
  async available(@CurrentUser() user: AuthUser, @Query() query: CursorQueryDto) {
    const courier = await this.status.courierFor(user.id);
    if (courier.status !== CourierStatus.AVAILABLE) return { items: [], nextCursor: null };
    const { orders, nextCursor } = await this.orders.page(
      { cityId: courier.cityId, status: OrderStatus.READY, courierId: null },
      query,
    );
    return { items: orders.map(toStaffOrderResponse), nextCursor };
  }

  /** Los pedidos que tomó, del más reciente al más antiguo. `scope=active|today`. */
  @Get('orders')
  async mine(@CurrentUser() user: AuthUser, @Query() query: CourierOrdersQueryDto) {
    const where = { AND: [scopeFor({ userId: user.id, role: Role.COURIER }), listScopeWhere(query.scope)] };
    const { orders, nextCursor } = await this.orders.page(where, query);
    return { items: orders.map(toStaffOrderResponse), nextCursor };
  }

  @Post('orders/:id/accept')
  @HttpCode(HttpStatus.OK)
  async accept(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return toStaffOrderResponse(await this.status.accept(user.id, id));
  }

  /** `status` = ON_THE_WAY, o DELIVERED con `collectedMethod` y `collectedAmount`. */
  @Post('orders/:id/status')
  @HttpCode(HttpStatus.OK)
  async advance(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: CourierAdvanceOrderDto) {
    const actor = { userId: user.id, role: Role.COURIER };
    const collection =
      dto.collectedMethod && dto.collectedAmount
        ? { method: dto.collectedMethod, amount: dto.collectedAmount.amount }
        : undefined;
    return toStaffOrderResponse(await this.status.advance(actor, id, dto.status, dto.note ?? undefined, collection));
  }
}
