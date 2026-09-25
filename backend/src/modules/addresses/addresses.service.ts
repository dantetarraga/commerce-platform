import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';
import { PrismaService } from '../../database/prisma.service';
import type { Address } from '../../generated/prisma/client';
import type { AddressBookDto, AddressKind } from './dto/address-book.dto';

function toAddressResponse(a: Address) {
  return {
    id: a.clientId,
    kind: a.kind as AddressKind,
    label: a.label,
    street: a.street,
    reference: a.reference ?? '',
    latitude: Number(a.latitude),
    longitude: Number(a.longitude),
  };
}

/**
 * Libreta de direcciones del usuario. La app es local primero: guarda en el
 * dispositivo y sube la libreta entera. El servidor la identifica por
 * (usuario, id de la app), así un id nunca toca direcciones de otra persona.
 */
@Injectable()
export class AddressesService {
  constructor(private readonly prisma: PrismaService) {}

  async book(userId: string) {
    const addresses = await this.prisma.address.findMany({
      where: { userId, deletedAt: null },
      orderBy: { createdAt: 'asc' },
    });
    return {
      selectedId: addresses.find((a) => a.isDefault)?.clientId ?? null,
      addresses: addresses.map(toAddressResponse),
    };
  }

  /** Reemplaza la libreta: crea o actualiza las que vienen y archiva las que faltan. */
  async replace(userId: string, dto: AddressBookDto) {
    const ids = dto.addresses.map((a) => a.id);
    if (new Set(ids).size !== ids.length) {
      throw new AppException(ErrorCode.VALIDATION_ERROR, HttpStatus.BAD_REQUEST, 'Hay direcciones repetidas.');
    }
    const selectedId = dto.selectedId && ids.includes(dto.selectedId) ? dto.selectedId : (ids[0] ?? null);

    await this.prisma.$transaction(async (tx) => {
      // Soft delete: los pedidos guardan su propio snapshot de la dirección.
      await tx.address.updateMany({
        where: { userId, deletedAt: null, clientId: { notIn: ids } },
        data: { deletedAt: new Date(), isDefault: false },
      });
      for (const a of dto.addresses) {
        const data = {
          kind: a.kind,
          label: a.label || null,
          street: a.street,
          reference: a.reference || null,
          latitude: a.latitude,
          longitude: a.longitude,
          isDefault: a.id === selectedId,
          deletedAt: null,
        };
        await tx.address.upsert({
          where: { userId_clientId: { userId, clientId: a.id } },
          create: { userId, clientId: a.id, ...data },
          update: data,
        });
      }
    });
    return this.book(userId);
  }
}
