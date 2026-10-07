import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../../common/decorators/auth.decorators';
import { Role } from '../../generated/prisma/enums';
import { AdminService } from './admin.service';
import { CreateCourierDto, CreateMerchantDto, FindUserQueryDto, SuspendPartnerDto } from './dto/admin.dto';

@ApiTags('admin')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  /** Cuenta por celular, con roles, negocios y vehículo. */
  @Get('users')
  find(@Query() query: FindUserQueryDto) {
    return this.admin.findByPhone(query.phone);
  }

  /** Si el celular no tiene cuenta, la crea. */
  @Post('merchants')
  createMerchant(@Body() dto: CreateMerchantDto) {
    return this.admin.createMerchant(dto);
  }

  /** Si el celular no tiene cuenta, la crea. Volver a llamarlo actualiza el vehículo. */
  @Post('couriers')
  createCourier(@Body() dto: CreateCourierDto) {
    return this.admin.createCourier(dto);
  }

  @Post('users/:id/suspend-partner')
  @HttpCode(HttpStatus.OK)
  suspendPartner(@Param('id') id: string, @Body() dto: SuspendPartnerDto) {
    return this.admin.suspendPartner(id, dto.roles);
  }
}
