import { Body, Controller, Get, HttpCode, HttpStatus, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../../common/decorators/auth.decorators';
import type { AuthUser } from '../../common/decorators/auth.decorators';
import { Role } from '../../generated/prisma/enums';
import { DayQueryDto } from '../../common/dto/day-query.dto';
import {
  AcceptOrderDto,
  AdvanceOrderDto,
  StaffCancelOrderDto,
  StaffOrdersQueryDto,
} from '../orders/dto/order-status.dto';
import { listScopeWhere } from '../orders/order-list-scope';
import { toStaffOrderResponse } from '../orders/order-presenter';
import { OrdersService } from '../orders/orders.service';
import { OrderActor, OrderStatusService, scopeFor } from '../orders/status/order-status.service';
import { StoresService } from '../stores/stores.service';
import { MerchantProductsQueryDto } from './dto/merchant-products-query.dto';
import { UpdateProductAvailabilityDto } from './dto/update-product-availability.dto';
import { UpdateStoreStatusDto } from './dto/update-store-status.dto';
import { MerchantService } from './merchant.service';

/** El admin opera cualquier negocio; el merchant, solo los suyos. */
const actorOf = (user: AuthUser): OrderActor => ({
  userId: user.id,
  role: user.roles.includes(Role.ADMIN) ? Role.ADMIN : Role.MERCHANT,
});

/** Filtro por dueño: el merchant solo toca lo suyo; el admin (undefined), todo. */
const ownerOf = (user: AuthUser) => (actorOf(user).role === Role.MERCHANT ? user.id : undefined);

/**
 * Operación del negocio (app Chaski Socios): ver sus pedidos, aceptarlos con
 * tiempo de preparación, marcarlos listos, cancelarlos, pausar la recepción,
 * marcar productos agotados y ver el resumen del día.
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
    private readonly merchant: MerchantService,
  ) {}

  @Get('stores')
  myStores(@CurrentUser() user: AuthUser) {
    return this.merchant.stores(ownerOf(user));
  }

  /** `scope=active|today` y `status` se combinan. */
  @Get('orders')
  async list(@CurrentUser() user: AuthUser, @Query() query: StaffOrdersQueryDto) {
    const where = {
      AND: [scopeFor(actorOf(user)), listScopeWhere(query.scope), query.status ? { status: query.status } : {}],
    };
    const { orders, nextCursor } = await this.orders.page(where, query);
    return { items: orders.map(toStaffOrderResponse), nextCursor };
  }

  @Get('orders/:id')
  async detail(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return toStaffOrderResponse(await this.status.find(actorOf(user), id));
  }

  /** Acepta un pedido nuevo: queda en PREPARING con la hora estimada recalculada. */
  @Post('orders/:id/accept')
  @HttpCode(HttpStatus.OK)
  async accept(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: AcceptOrderDto) {
    return toStaffOrderResponse(await this.status.acceptByMerchant(actorOf(user), id, dto.prepMinutes));
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
    return this.stores.setAcceptingOrders(id, dto.isAcceptingOrders, ownerOf(user));
  }

  @Get('stores/:id/products')
  products(@CurrentUser() user: AuthUser, @Param('id') id: string, @Query() query: MerchantProductsQueryDto) {
    return this.merchant.products(id, query, ownerOf(user));
  }

  /** Marca un producto disponible o agotado. */
  @Patch('products/:id')
  updateProduct(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateProductAvailabilityDto) {
    return this.merchant.setProductAvailable(id, dto.isAvailable, ownerOf(user));
  }

  /** Resumen del día (hora de Lima) de sus negocios. */
  @Get('summary')
  summary(@CurrentUser() user: AuthUser, @Query() query: DayQueryDto) {
    return this.merchant.summary(query.date, ownerOf(user));
  }
}
