import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../../../common/decorators/auth.decorators';
import { Role } from '../../../generated/prisma/enums';
import { AnalyticsQueryDto } from './admin-analytics.dto';
import { AdminAnalyticsService } from './admin-analytics.service';

/** Métricas del inicio del admin, calculadas aquí: la web solo las dibuja. */
@ApiTags('admin · métricas')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin/analytics')
export class AdminAnalyticsController {
  constructor(private readonly analytics: AdminAnalyticsService) {}

  /** Cifras del rango comparadas con el periodo anterior, por día, hora, motivo y negocio. */
  @Get()
  report(@Query() query: AnalyticsQueryDto) {
    return this.analytics.report(query.from, query.to, query.cityId);
  }
}
