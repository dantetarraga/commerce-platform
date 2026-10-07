import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../../../common/decorators/auth.decorators';
import { Role } from '../../../generated/prisma/enums';
import { AdminPartnersService } from './admin-partners.service';
import { CreateCourierDto, CreateMerchantDto, FindUserQueryDto, SuspendPartnerDto } from './partners.dto';

@ApiTags('admin')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin')
export class AdminPartnersController {
  constructor(private readonly partners: AdminPartnersService) {}

  /** Cuenta por celular, con roles, negocios y vehículo. */
  @Get('users')
  find(@Query() query: FindUserQueryDto) {
    return this.partners.findByPhone(query.phone);
  }

  /** Si el celular no tiene cuenta, la crea. */
  @Post('merchants')
  createMerchant(@Body() dto: CreateMerchantDto) {
    return this.partners.createMerchant(dto);
  }

  /** Si el celular no tiene cuenta, la crea. Volver a llamarlo actualiza el vehículo. */
  @Post('couriers')
  createCourier(@Body() dto: CreateCourierDto) {
    return this.partners.createCourier(dto);
  }

  @Post('users/:id/suspend-partner')
  @HttpCode(HttpStatus.OK)
  suspendPartner(@Param('id') id: string, @Body() dto: SuspendPartnerDto) {
    return this.partners.suspendPartner(id, dto.roles);
  }
}
