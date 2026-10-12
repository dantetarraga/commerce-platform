import { randomUUID } from 'node:crypto';
import { HttpStatus, Injectable } from '@nestjs/common';
import type { AuthUser } from '../../common/decorators/auth.decorators';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';
import { PrismaService } from '../../database/prisma.service';
import { Role } from '../../generated/prisma/enums';
import { imageKey, isStoreImage } from './image-keys';
import { ObjectStorage } from './object-storage';
import { ImageUploadDto } from './upload.dto';

@Injectable()
export class UploadsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: ObjectStorage,
  ) {}

  /** El dueño sube fotos de sus negocios; promociones y categorías, solo el equipo. */
  async signImageUpload(dto: ImageUploadDto, user: AuthUser) {
    const isAdmin = user.roles.includes(Role.ADMIN);
    if (isStoreImage(dto.purpose)) {
      const count = await this.prisma.store.count({
        where: { id: dto.storeId, deletedAt: null, ...(!isAdmin && { ownerId: user.id }) },
      });
      if (count === 0) throw AppException.notFound('No encontramos ese negocio.');
    } else if (!isAdmin) {
      throw new AppException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, 'Esa foto la sube el equipo Apamuy.');
    }
    const key = imageKey(dto.purpose, dto.contentType, randomUUID(), dto.storeId);
    return this.storage.signUpload(key, dto.contentType, dto.size);
  }
}
