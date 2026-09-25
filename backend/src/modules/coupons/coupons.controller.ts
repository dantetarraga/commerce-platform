import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/auth.decorators';
import type { AuthUser } from '../../common/decorators/auth.decorators';
import { pointOf } from '../../common/dto/location-query.dto';
import { CouponsService } from './coupons.service';
import { ValidateCouponDto } from './dto/validate-coupon.dto';

@ApiTags('checkout')
@ApiBearerAuth()
@Controller('coupons')
export class CouponsController {
  constructor(private readonly coupons: CouponsService) {}

  @Post('validate')
  @HttpCode(HttpStatus.OK)
  validate(@CurrentUser() user: AuthUser, @Body() dto: ValidateCouponDto) {
    return this.coupons.quote(user.id, dto.code, dto.storeId, dto.subtotal.amount, pointOf(dto));
  }
}
