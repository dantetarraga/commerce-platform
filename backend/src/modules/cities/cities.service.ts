import { Injectable } from '@nestjs/common';
import { GeoPoint, haversineKm } from '../../common/utils/geo';
import { PrismaService } from '../../database/prisma.service';
import type { City } from '../../generated/prisma/client';
import type { DeliveryTariff } from '../delivery/delivery';

/** Ciudad con los Decimal ya convertidos, lista para los cálculos. */
export interface CityContext {
  id: string;
  name: string;
  timezone: string;
  currency: string;
  center: GeoPoint;
  tariff: DeliveryTariff;
}

export function toCityContext(city: City): CityContext {
  return {
    id: city.id,
    name: city.name,
    timezone: city.timezone,
    currency: city.currency,
    center: { lat: Number(city.centerLat), lng: Number(city.centerLng) },
    tariff: {
      baseDeliveryFee: city.baseDeliveryFee,
      feePerKm: city.feePerKm,
      routeFactor: Number(city.routeFactor),
      maxDeliveryKm: Number(city.maxDeliveryKm),
      avgSpeedKmh: city.avgSpeedKmh,
    },
  };
}

@Injectable()
export class CitiesService {
  constructor(private readonly prisma: PrismaService) {}

  async listActive() {
    const cities = await this.prisma.city.findMany({ where: { isActive: true }, orderBy: { createdAt: 'asc' } });
    return cities.map((city) => ({
      id: city.id,
      name: city.name,
      region: city.region,
      slug: city.slug,
      currency: city.currency,
      centerLat: Number(city.centerLat),
      centerLng: Number(city.centerLng),
    }));
  }

  /**
   * Ciudad que corresponde a una ubicación: la activa con el centro más
   * cercano. Sin ubicación, la primera ciudad activa.
   */
  async resolve(point?: GeoPoint): Promise<CityContext | null> {
    const cities = (await this.prisma.city.findMany({ where: { isActive: true }, orderBy: { createdAt: 'asc' } })).map(
      toCityContext,
    );
    if (!point || cities.length <= 1) return cities[0] ?? null;
    return cities.reduce((best, city) =>
      haversineKm(city.center, point) < haversineKm(best.center, point) ? city : best,
    );
  }

  async byId(cityId: string): Promise<CityContext> {
    return toCityContext(await this.prisma.city.findUniqueOrThrow({ where: { id: cityId } }));
  }
}
