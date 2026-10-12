import { Body, Controller, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../../common/decorators/auth.decorators';
import type { AuthUser } from '../../common/decorators/auth.decorators';
import { Role } from '../../generated/prisma/enums';
import { ImageUploadDto } from './upload.dto';
import { UploadsService } from './uploads.service';

@ApiTags('fotos')
@ApiBearerAuth()
@Roles(Role.MERCHANT, Role.ADMIN)
@Controller('uploads')
export class UploadsController {
  constructor(private readonly uploads: UploadsService) {}

  /**
   * URL firmada (5 minutos) para subir una foto directo al storage con un PUT. Después se
   * guarda `publicUrl` en el producto, negocio o promoción.
   */
  @Post('images')
  signImage(@CurrentUser() user: AuthUser, @Body() dto: ImageUploadDto) {
    return this.uploads.signImageUpload(dto, user);
  }
}
