import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../../common/exceptions/app.exception';
import { money } from '../../../common/utils/money';
import { PrismaService } from '../../../database/prisma.service';
import { City } from '../../../generated/prisma/client';
import { OrderStatus } from '../../../generated/prisma/enums';
import { toCityContext } from '../../cities/cities.service';
import { tariffExamples } from '../../delivery/delivery';
import { freeSlug, slugify } from '../catalog/catalog-rules';
import { CityDto, UpdateCityDto } from './admin-cities.dto';

type CityWithCounts = City & { _count: { stores: number; couriers: number } };

function toAdminCity(city: CityWithCounts) {
  const { tariff } = toCityContext(city);
  return {
    id: city.id,
    name: city.name,
    region: city.region,
    slug: city.slug,
    timezone: city.timezone,
    currency: city.currency,
    centerLat: Number(city.centerLat),
    centerLng: Number(city.centerLng),
    coverageKm: Number(city.coverageKm),
    maxDeliveryKm: tariff.maxDeliveryKm,
    baseDeliveryFee: money(city.baseDeliveryFee, city.currency),
    feePerKm: money(city.feePerKm, city.currency),
    routeFactor: tariff.routeFactor,
    avgSpeedKmh: city.avgSpeedKmh,
    isActive: city.isActive,
    storeCount: city._count.stores,
    courierCount: city._count.couriers,
    feeExamples: tariffExamples(tariff).map(({ fee, ...example }) => ({
      ...example,
      fee: money(fee, city.currency),
    })),
  };
}

const withCounts = { _count: { select: { stores: true, couriers: true } } } as const;

/** Ciudades y sus parámetros de reparto, editados por el admin. */
@Injectable()
export class AdminCitiesService {
  constructor(private readonly prisma: PrismaService) {}

  /** Incluye las inactivas. */
  async list() {
    const cities = await this.prisma.city.findMany({ include: withCounts, orderBy: { createdAt: 'asc' } });
    return cities.map(toAdminCity);
  }

  async create(dto: CityDto) {
    const base = slugify(dto.name) || 'ciudad';
    const taken = await this.prisma.city.findMany({
      where: { slug: { startsWith: base } },
      select: { slug: true },
    });
    const city = await this.prisma.city.create({
      data: {
        name: dto.name,
        region: dto.region,
        slug: freeSlug(base, new Set(taken.map(({ slug }) => slug))),
        centerLat: dto.centerLat,
        centerLng: dto.centerLng,
        coverageKm: dto.coverageKm,
        maxDeliveryKm: dto.maxDeliveryKm,
        baseDeliveryFee: dto.baseDeliveryFee.amount,
        feePerKm: dto.feePerKm.amount,
        routeFactor: dto.routeFactor,
        avgSpeedKmh: dto.avgSpeedKmh,
        // Las ciudades nuevas se configuran antes de recibir pedidos.
        isActive: dto.isActive ?? false,
      },
      include: withCounts,
    });
    return toAdminCity(city);
  }

  async update(id: string, dto: UpdateCityDto) {
    const current = await this.prisma.city.findUnique({ where: { id }, select: { id: true } });
    if (!current) throw AppException.notFound('No encontramos esa ciudad.');
    if (dto.isActive === false) await this.assertCanDeactivate(id);
    const city = await this.prisma.city.update({ where: { id }, data: this.data(dto), include: withCounts });
    return toAdminCity(city);
  }

  /** Apagar una ciudad con pedidos en curso dejaría a esos clientes sin seguimiento. */
  private async assertCanDeactivate(cityId: string) {
    const ongoing = await this.prisma.order.count({
      where: { cityId, status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] } },
    });
    if (ongoing > 0) {
      throw new AppException(
        ErrorCode.CONFLICT,
        HttpStatus.CONFLICT,
        `La ciudad tiene ${ongoing} pedido(s) en curso. Desactívala cuando terminen.`,
      );
    }
  }

  private data(dto: UpdateCityDto) {
    return {
      name: dto.name,
      region: dto.region,
      centerLat: dto.centerLat,
      centerLng: dto.centerLng,
      coverageKm: dto.coverageKm,
      maxDeliveryKm: dto.maxDeliveryKm,
      baseDeliveryFee: dto.baseDeliveryFee?.amount,
      feePerKm: dto.feePerKm?.amount,
      routeFactor: dto.routeFactor,
      avgSpeedKmh: dto.avgSpeedKmh,
      isActive: dto.isActive,
    };
  }
}
