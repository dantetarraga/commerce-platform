import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../../../common/decorators/auth.decorators';
import { Role } from '../../../generated/prisma/enums';
import { AdminMarketingService } from './admin-marketing.service';
import { CityQueryDto, CouponDto, PromotionDto, UpdateCouponDto, UpdatePromotionDto } from './marketing.dto';

/** Cupones y banners del inicio. */
@ApiTags('admin · promociones')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin')
export class AdminMarketingController {
  constructor(private readonly marketing: AdminMarketingService) {}

  /** Todos, con cuántas veces se usaron. */
  @Get('coupons')
  listCoupons() {
    return this.marketing.listCoupons();
  }

  /** `percentOff` para PERCENTAGE, `amountOff` para FIXED_AMOUNT; FREE_DELIVERY no lleva monto. */
  @Post('coupons')
  createCoupon(@Body() dto: CouponDto) {
    return this.marketing.createCoupon(dto);
  }

  /** El código no cambia. Para darlo de baja: `isActive: false`. */
  @Patch('coupons/:id')
  updateCoupon(@Param('id') id: string, @Body() dto: UpdateCouponDto) {
    return this.marketing.updateCoupon(id, dto);
  }

  /** Incluye las vencidas y las desactivadas. */
  @Get('promotions')
  listPromotions(@Query() query: CityQueryDto) {
    return this.marketing.listPromotions(query.cityId);
  }

  @Post('promotions')
  createPromotion(@Body() dto: PromotionDto) {
    return this.marketing.createPromotion(dto);
  }

  @Patch('promotions/:id')
  updatePromotion(@Param('id') id: string, @Body() dto: UpdatePromotionDto) {
    return this.marketing.updatePromotion(id, dto);
  }

  @Delete('promotions/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  removePromotion(@Param('id') id: string) {
    return this.marketing.removePromotion(id);
  }
}
