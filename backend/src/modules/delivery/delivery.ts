import { GeoPoint, haversineKm } from '../../common/utils/geo';

/** Parámetros de delivery de la ciudad (céntimos, km, km/h). */
export interface DeliveryTariff {
  baseDeliveryFee: number;
  feePerKm: number;
  routeFactor: number;
  maxDeliveryKm: number;
  avgSpeedKmh: number;
}

export interface DeliveryOrigin {
  location: GeoPoint;
  deliveryRadiusKm: number | null;
  avgPrepMinutes: number;
}

export interface DeliveryEstimate {
  /** Distancia estimada por calle, redondeada a 0.1 km. */
  distanceKm: number;
  deliversToYou: boolean;
  fee: number;
  etaMinutes: number;
}

/**
 * Cálculo de delivery del MVP:
 * - km por calle = Haversine × routeFactor;
 * - cobertura = km ≤ radio del negocio (o el máximo de la ciudad);
 * - fee = base + ceil(km) × feePerKm;
 * - ETA = preparación + viaje, redondeado hacia arriba a múltiplos de 5.
 */
export function estimateDelivery(
  origin: DeliveryOrigin,
  destination: GeoPoint,
  tariff: DeliveryTariff,
): DeliveryEstimate {
  const km = haversineKm(origin.location, destination) * tariff.routeFactor;
  const radiusKm = origin.deliveryRadiusKm ?? tariff.maxDeliveryKm;
  const travelMinutes = (km / tariff.avgSpeedKmh) * 60;
  return {
    distanceKm: Math.round(km * 10) / 10,
    deliversToYou: km <= radiusKm,
    fee: tariff.baseDeliveryFee + Math.ceil(km) * tariff.feePerKm,
    etaMinutes: Math.ceil((origin.avgPrepMinutes + travelMinutes) / 5) * 5,
  };
}
