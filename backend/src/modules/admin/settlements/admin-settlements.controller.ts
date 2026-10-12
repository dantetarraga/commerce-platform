import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../../../common/decorators/auth.decorators';
import type { AuthUser } from '../../../common/decorators/auth.decorators';
import { Role } from '../../../generated/prisma/enums';
import { AdminSettlementsService } from './admin-settlements.service';
import {
  AdminSettlementsQueryDto,
  CommissionRateDto,
  MarkSettlementPaidDto,
  SettlementWeekQueryDto,
  StoreCommissionDto,
} from './settlements.dto';

/** Comisión de Apamuy y liquidaciones semanales a los negocios. */
@ApiTags('admin · liquidaciones')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin')
export class AdminSettlementsController {
  constructor(private readonly settlements: AdminSettlementsService) {}

  /** Comisión por defecto sobre el subtotal de productos, en puntos básicos (1000 = 10 %). */
  @Get('commission')
  commission() {
    return this.settlements.commissionSettings();
  }

  /** Cambia la comisión por defecto. Los pedidos ya creados conservan la suya. */
  @Put('commission')
  setCommission(@CurrentUser() user: AuthUser, @Body() dto: CommissionRateDto) {
    return this.settlements.setDefaultRate(dto.rateBps, user.id);
  }

  @Get('stores/:id/commission')
  storeCommission(@Param('id') id: string) {
    return this.settlements.storeCommission(id);
  }

  /** `rateBps: null` vuelve a la comisión por defecto. */
  @Put('stores/:id/commission')
  setStoreCommission(@Param('id') id: string, @Body() dto: StoreCommissionDto) {
    return this.settlements.setStoreCommission(id, dto.rateBps);
  }

  /** La semana (lunes a domingo) de cada negocio que vendió: vendido, comisión, saldo y si ya se pagó. */
  @Get('settlements')
  week(@Query() query: AdminSettlementsQueryDto) {
    return this.settlements.week(query.week, { cityId: query.cityId });
  }

  @Get('settlements/:storeId')
  detail(@Param('storeId') storeId: string, @Query() query: SettlementWeekQueryDto) {
    return this.settlements.detail(storeId, query.week);
  }

  /** Marca la semana como pagada (quién y cuándo). Solo semanas terminadas y con pedidos. */
  @Post('settlements/:storeId/pay')
  @HttpCode(HttpStatus.OK)
  markPaid(@CurrentUser() user: AuthUser, @Param('storeId') storeId: string, @Body() dto: MarkSettlementPaidDto) {
    return this.settlements.markPaid(storeId, dto.week, user.id);
  }
}
