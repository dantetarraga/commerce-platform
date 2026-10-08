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
  /** Radio de la zona de reparto alrededor de [center]. */
  coverageKm: number;
  tariff: DeliveryTariff;
}

/** Si [point] cae en la zona de reparto de la ciudad. */
export function inCoverage(city: CityContext, point: GeoPoint): boolean {
  return haversineKm(city.center, point) <= city.coverageKm;
}

export function toCityContext(city: City): CityContext {
  return {
    id: city.id,
    name: city.name,
    timezone: city.timezone,
    currency: city.currency,
    center: { lat: Number(city.centerLat), lng: Number(city.centerLng) },
    coverageKm: Number(city.coverageKm),
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
      coverageKm: Number(city.coverageKm),
    }));
  }

  /**
   * Ciudad que corresponde a una ubicación: la activa con el centro más
   * cercano. Sin ubicación, la primera ciudad activa.
   */
  async resolve(point?: GeoPoint): Promise<CityContext | null> {
    const cities = await this.active();
    if (!point || cities.length <= 1) return cities[0] ?? null;
    return cities.reduce((best, city) =>
      haversineKm(city.center, point) < haversineKm(best.center, point) ? city : best,
    );
  }

  async active(): Promise<CityContext[]> {
    const cities = await this.prisma.city.findMany({ where: { isActive: true }, orderBy: { createdAt: 'asc' } });
    return cities.map(toCityContext);
  }

  async byId(cityId: string): Promise<CityContext> {
    return toCityContext(await this.prisma.city.findUniqueOrThrow({ where: { id: cityId } }));
  }
}
