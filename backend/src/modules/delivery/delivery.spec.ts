import { haversineKm } from '../../common/utils/geo';
import { DeliveryTariff, estimateDelivery } from './delivery';

const tariff: DeliveryTariff = {
  baseDeliveryFee: 250,
  feePerKm: 100,
  routeFactor: 1.3,
  maxDeliveryKm: 5,
  avgSpeedKmh: 20,
};
const plaza = { lat: -14.7936, lng: -71.4128 };
const origin = { location: plaza, deliveryRadiusKm: null, avgPrepMinutes: 20 };

describe('haversineKm', () => {
  it('~1.11 km por cada 0.01° de latitud', () => {
    expect(haversineKm(plaza, { lat: plaza.lat + 0.01, lng: plaza.lng })).toBeCloseTo(1.112, 2);
  });
});

describe('estimateDelivery', () => {
  it('aplica el factor de ruta a la distancia en línea recta', () => {
    const destination = { lat: plaza.lat + 0.01, lng: plaza.lng };
    expect(estimateDelivery(origin, destination, tariff).distanceKm).toBe(1.4); // 1.112 × 1.3
  });

  it('fee = base + km redondeados hacia arriba × tarifa por km', () => {
    const destination = { lat: plaza.lat + 0.01, lng: plaza.lng }; // 1.45 km por calle → 2 km
    expect(estimateDelivery(origin, destination, tariff).fee).toBe(450);
  });

  it('en el mismo punto cobra solo la base y el ETA es la preparación', () => {
    expect(estimateDelivery(origin, plaza, tariff)).toEqual({
      distanceKm: 0,
      deliversToYou: true,
      fee: 250,
      etaMinutes: 20,
    });
  });

  it('el ETA suma el viaje y se redondea a múltiplos de 5', () => {
    const destination = { lat: plaza.lat + 0.02, lng: plaza.lng }; // 2.9 km a 20 km/h ≈ 8.7 min
    expect(estimateDelivery(origin, destination, tariff).etaMinutes).toBe(30);
  });

  it('fuera del radio de la ciudad no entrega', () => {
    const far = { lat: plaza.lat + 0.05, lng: plaza.lng }; // ~7.2 km por calle
    expect(estimateDelivery(origin, far, tariff).deliversToYou).toBe(false);
  });

  it('el radio propio del negocio reemplaza al de la ciudad', () => {
    const destination = { lat: plaza.lat + 0.02, lng: plaza.lng };
    expect(estimateDelivery({ ...origin, deliveryRadiusKm: 2 }, destination, tariff).deliversToYou).toBe(false);
  });
});
