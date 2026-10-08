import { CityContext, inCoverage } from './cities.service';

const espinar = { center: { lat: -14.7936, lng: -71.4128 }, coverageKm: 6 } as CityContext;

describe('inCoverage', () => {
  it('acepta puntos dentro del radio y rechaza los de fuera', () => {
    expect(inCoverage(espinar, espinar.center)).toBe(true);
    // 0.05° de latitud ≈ 5.6 km; 0.06° ≈ 6.7 km.
    expect(inCoverage(espinar, { lat: -14.7436, lng: -71.4128 })).toBe(true);
    expect(inCoverage(espinar, { lat: -14.7336, lng: -71.4128 })).toBe(false);
  });
});
