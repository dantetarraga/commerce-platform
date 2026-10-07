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

/**
 * Nueva hora estimada de entrega cuando el negocio acepta y dice cuánto tarda:
 * ahora + `prepMinutes` + viaje (distancia por calle ya guardada en el pedido
 * ÷ velocidad media de la ciudad), redondeado hacia arriba a múltiplos de 5
 * como `estimateDelivery`. Un pedido programado no se estima antes de su hora.
 */
export function estimateAfterAccept(input: {
  now: Date;
  prepMinutes: number;
  distanceMeters: number;
  avgSpeedKmh: number;
  scheduledFor?: Date | null;
}): Date {
  const estimated = after(input.now, input.prepMinutes + travelMinutes(input.distanceMeters, input.avgSpeedKmh));
  return input.scheduledFor && input.scheduledFor > estimated ? input.scheduledFor : estimated;
}

/** Al salir el repartidor del local solo falta el viaje: ahora + viaje, en múltiplos de 5. */
export function estimateOnTheWay(input: { now: Date; distanceMeters: number; avgSpeedKmh: number }): Date {
  return after(input.now, travelMinutes(input.distanceMeters, input.avgSpeedKmh));
}

const travelMinutes = (distanceMeters: number, avgSpeedKmh: number) => (distanceMeters / 1000 / avgSpeedKmh) * 60;

/** `now` + `minutes` redondeado hacia arriba a múltiplos de 5 (al menos 5). */
function after(now: Date, minutes: number): Date {
  const rounded = Math.max(5, Math.ceil(minutes / 5) * 5);
  return new Date(now.getTime() + rounded * 60_000);
}
