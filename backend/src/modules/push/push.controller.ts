import { Body, Controller, Delete, HttpCode, HttpStatus, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/auth.decorators';
import type { AuthUser } from '../../common/decorators/auth.decorators';
import { RegisterDeviceDto, UnregisterDeviceDto } from './push.dto';
import { PushService } from './push.service';

/** Teléfonos que reciben push de la cuenta. */
@ApiTags('users')
@ApiBearerAuth()
@Controller('users/me/devices')
export class PushController {
  constructor(private readonly push: PushService) {}

  /** Al iniciar sesión y cada vez que FCM renueva el token. Idempotente. */
  @Put()
  @HttpCode(HttpStatus.NO_CONTENT)
  register(@CurrentUser() user: AuthUser, @Body() dto: RegisterDeviceDto) {
    return this.push.register(user.id, dto.pushToken, dto.platform, dto.app);
  }

  /** Antes de cerrar sesión. */
  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  unregister(@CurrentUser() user: AuthUser, @Body() dto: UnregisterDeviceDto) {
    return this.push.unregister(user.id, dto.pushToken);
  }
}
