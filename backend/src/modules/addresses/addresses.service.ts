import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';
import { PrismaService } from '../../database/prisma.service';
import type { Address } from '../../generated/prisma/client';
import { CitiesService, inCoverage } from '../cities/cities.service';
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
  constructor(
    private readonly prisma: PrismaService,
    private readonly cities: CitiesService,
  ) {}

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
    const cityOf = await this.checkCoverage(userId, dto);

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
          cityId: cityOf.get(a.id) ?? null,
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

  /**
   * Ciudad de cada dirección. Rechaza las nuevas o movidas fuera de la zona de
   * reparto; las que ya estaban se aceptan igual para no trabar la sincronización.
   */
  private async checkCoverage(userId: string, dto: AddressBookDto): Promise<Map<string, string>> {
    const stored = await this.prisma.address.findMany({
      where: { userId, clientId: { in: dto.addresses.map((a) => a.id) } },
      select: { clientId: true, latitude: true, longitude: true },
    });
    const storedById = new Map(stored.map((a) => [a.clientId, a]));
    const cities = await this.cities.active();
    const cityOf = new Map<string, string>();
    const outside: string[] = [];
    for (const a of dto.addresses) {
      const city = cities.find((c) => inCoverage(c, { lat: a.latitude, lng: a.longitude }));
      if (city) {
        cityOf.set(a.id, city.id);
        continue;
      }
      const before = storedById.get(a.id);
      const moved = !before || Number(before.latitude) !== a.latitude || Number(before.longitude) !== a.longitude;
      if (moved) outside.push(a.id);
    }
    if (outside.length > 0) {
      throw new AppException(
        ErrorCode.ADDRESS_OUT_OF_COVERAGE,
        HttpStatus.UNPROCESSABLE_ENTITY,
        'Esa dirección está fuera de la zona de reparto.',
        { ids: outside },
      );
    }
    return cityOf;
  }
}
