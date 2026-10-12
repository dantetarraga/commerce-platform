import { commissionOf, effectiveRateBps } from './commission';

describe('commissionOf', () => {
  it('aplica el porcentaje al subtotal', () => {
    expect(commissionOf(4200, 1000)).toBe(420);
    expect(commissionOf(4200, 0)).toBe(0);
    expect(commissionOf(4200, 10_000)).toBe(4200);
  });

  it('redondea al céntimo más cercano', () => {
    expect(commissionOf(1999, 1250)).toBe(250); // 249.875
    expect(commissionOf(1001, 1250)).toBe(125); // 125.125
    expect(commissionOf(4, 1250)).toBe(1); // 0.5
  });
});

describe('effectiveRateBps', () => {
  it('usa la del negocio si tiene una, aunque sea 0', () => {
    expect(effectiveRateBps(800, 1000)).toBe(800);
    expect(effectiveRateBps(0, 1000)).toBe(0);
    expect(effectiveRateBps(null, 1000)).toBe(1000);
  });
});
