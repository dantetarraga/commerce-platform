import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';
import { Public } from '../../common/decorators/auth.decorators';
import { PromotionsService } from './promotions.service';

export class PromotionsQueryDto {
  /** Sin ciudad: las promociones vigentes de todas las ciudades activas. */
  @IsOptional()
  @IsString()
  cityId?: string;
}

@ApiTags('catalog')
@Public()
@Controller('promotions')
export class PromotionsController {
  constructor(private readonly promotions: PromotionsService) {}

  @Get()
  list(@Query() query: PromotionsQueryDto) {
    return this.promotions.active(query.cityId);
  }
}
