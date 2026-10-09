import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../../../common/decorators/auth.decorators';
import { Role } from '../../../generated/prisma/enums';
import { AdminCashQueryDto } from './admin-cash.dto';
import { AdminCashService } from './admin-cash.service';

/** Rendición diaria del efectivo, Yape y Plin cobrados contraentrega. */
@ApiTags('admin · caja')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin/cash')
export class AdminCashController {
  constructor(private readonly cash: AdminCashService) {}

  /** Pedidos entregados ese día: por repartidor (cobrado vs. esperado) y por negocio. */
  @Get()
  day(@Query() query: AdminCashQueryDto) {
    return this.cash.day(query.date, query.cityId);
  }
}
