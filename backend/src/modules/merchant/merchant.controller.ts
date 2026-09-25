import { Body, Controller, Get, HttpCode, HttpStatus, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../../common/decorators/auth.decorators';
import type { AuthUser } from '../../common/decorators/auth.decorators';
import { Role } from '../../generated/prisma/enums';
import { AdvanceOrderDto, StaffCancelOrderDto, StaffOrdersQueryDto } from '../orders/dto/order-status.dto';
import { toStaffOrderResponse } from '../orders/order-presenter';
import { OrdersService } from '../orders/orders.service';
import { OrderActor, OrderStatusService, scopeFor } from '../orders/status/order-status.service';
import { StoresService } from '../stores/stores.service';
import { UpdateStoreStatusDto } from './dto/update-store-status.dto';

/** El admin opera cualquier negocio; el merchant, solo los suyos. */
const actorOf = (user: AuthUser): OrderActor => ({
  userId: user.id,
  role: user.roles.includes(Role.ADMIN) ? Role.ADMIN : Role.MERCHANT,
});

/**
 * Operación del negocio: ver sus pedidos, confirmarlos, prepararlos,
 * marcarlos listos, cancelarlos y pausar la recepción de pedidos. Hasta que
 * exista el panel web se usa desde Swagger.
 */
@ApiTags('merchant')
@ApiBearerAuth()
@Roles(Role.MERCHANT, Role.ADMIN)
@Controller('merchant')
export class MerchantController {
  constructor(
    private readonly stores: StoresService,
    private readonly orders: OrdersService,
    private readonly status: OrderStatusService,
  ) {}

  @Get('orders')
  async list(@CurrentUser() user: AuthUser, @Query() query: StaffOrdersQueryDto) {
    const where = { ...scopeFor(actorOf(user)), ...(query.status && { status: query.status }) };
    const { orders, nextCursor } = await this.orders.page(where, query);
    return { items: orders.map(toStaffOrderResponse), nextCursor };
  }

  @Get('orders/:id')
  async detail(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return toStaffOrderResponse(await this.status.find(actorOf(user), id));
  }

  /** `status` = el siguiente paso: CONFIRMED, PREPARING o READY. */
  @Post('orders/:id/status')
  @HttpCode(HttpStatus.OK)
  async advance(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: AdvanceOrderDto) {
    return toStaffOrderResponse(await this.status.advance(actorOf(user), id, dto.status, dto.note ?? undefined));
  }

  @Post('orders/:id/cancel')
  @HttpCode(HttpStatus.OK)
  async cancel(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: StaffCancelOrderDto) {
    return toStaffOrderResponse(await this.status.cancel(actorOf(user), id, dto.reason));
  }

  /** Pausa o reanuda la recepción de pedidos (p. ej. cocina llena). */
  @Patch('stores/:id')
  updateStore(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateStoreStatusDto) {
    const ownerId = actorOf(user).role === Role.MERCHANT ? user.id : undefined;
    return this.stores.setAcceptingOrders(id, dto.isAcceptingOrders, ownerId);
  }
}
