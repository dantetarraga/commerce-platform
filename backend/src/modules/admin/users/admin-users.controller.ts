import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../../../common/decorators/auth.decorators';
import type { AuthUser } from '../../../common/decorators/auth.decorators';
import { Role } from '../../../generated/prisma/enums';
import { BlockUserDto, ListUsersQueryDto, RestorePartnerDto, SetAdminDto } from './admin-users.dto';
import { AdminUsersService } from './admin-users.service';

/** Todas las cuentas: clientes, socios y equipo. Cada cambio queda en su historial. */
@ApiTags('admin · usuarios')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin/users')
export class AdminUsersController {
  constructor(private readonly users: AdminUsersService) {}

  /** `{ items, page, pageSize, total }`, de la más nueva a la más antigua. */
  @Get()
  list(@Query() query: ListUsersQueryDto) {
    return this.users.list(query);
  }

  /** Datos, pedidos, sesiones, desempeño de socio (30 días) e historial de cambios. */
  @Get(':id')
  detail(@Param('id') id: string) {
    return this.users.detail(id);
  }

  @Post(':id/block')
  @HttpCode(HttpStatus.OK)
  block(@CurrentUser() admin: AuthUser, @Param('id') id: string, @Body() dto: BlockUserDto) {
    return this.users.block(admin.id, id, dto.reason);
  }

  @Post(':id/unblock')
  @HttpCode(HttpStatus.OK)
  unblock(@CurrentUser() admin: AuthUser, @Param('id') id: string) {
    return this.users.unblock(admin.id, id);
  }

  /** Devuelve los roles de socio que quitó una suspensión. */
  @Post(':id/restore-partner')
  @HttpCode(HttpStatus.OK)
  restorePartner(@CurrentUser() admin: AuthUser, @Param('id') id: string, @Body() dto: RestorePartnerDto) {
    return this.users.restorePartner(admin.id, id, dto.roles);
  }

  /** Cierra sus sesiones en todos los teléfonos y navegadores. */
  @Post(':id/revoke-sessions')
  @HttpCode(HttpStatus.OK)
  revokeSessions(@CurrentUser() admin: AuthUser, @Param('id') id: string) {
    return this.users.revokeSessions(admin.id, id);
  }

  @Put(':id/admin')
  setAdmin(@CurrentUser() admin: AuthUser, @Param('id') id: string, @Body() dto: SetAdminDto) {
    return this.users.setAdmin(admin.id, id, dto.isAdmin);
  }
}
