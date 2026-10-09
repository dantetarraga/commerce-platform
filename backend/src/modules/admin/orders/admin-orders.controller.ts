import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../../../common/decorators/auth.decorators';
import type { AuthUser } from '../../../common/decorators/auth.decorators';
import { Role } from '../../../generated/prisma/enums';
import { StaffCancelOrderDto } from '../../orders/dto/order-status.dto';
import { AdminBoardQueryDto, AdminOrdersQueryDto } from './admin-orders.dto';
import { AdminOrdersService } from './admin-orders.service';

/** Pedidos en vivo de todas las ciudades. */
@ApiTags('admin · pedidos')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin/orders')
export class AdminOrdersController {
  constructor(private readonly orders: AdminOrdersService) {}

  /** En curso por columna; `alert: 'late'` en los que esperan respuesta 3 minutos o más. */
  @Get('board')
  board(@Query() query: AdminBoardQueryDto) {
    return this.orders.board(query.cityId);
  }

  /** Pedidos de un día (hoy por defecto), con cursor. */
  @Get()
  list(@Query() query: AdminOrdersQueryDto) {
    return this.orders.list(query);
  }

  @Get(':id')
  detail(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.orders.detail(user.id, id);
  }

  @Post(':id/cancel')
  cancel(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: StaffCancelOrderDto) {
    return this.orders.cancel(user.id, id, dto.reason);
  }
}
