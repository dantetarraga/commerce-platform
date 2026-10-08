import { FilterableStore, matchesFilters, openFirst } from './store-filters';

const store = (overrides: Partial<FilterableStore> = {}): FilterableStore => ({
  isOpenNow: true,
  estimatedDeliveryFee: { amount: 300 },
  minOrderAmount: { amount: 1500 },
  ratingAvg: 4.2,
  ratingCount: 10,
  promoLabel: null,
  ...overrides,
});

describe('matchesFilters', () => {
  it('sin filtros pasa cualquiera', () => {
    expect(matchesFilters(store({ isOpenNow: false }), [])).toBe(true);
  });

  it('cada filtro mira su dato y se combinan con Y', () => {
    expect(matchesFilters(store({ isOpenNow: false }), ['open_now'])).toBe(false);
    expect(matchesFilters(store({ estimatedDeliveryFee: { amount: 0 } }), ['free_delivery'])).toBe(true);
    expect(matchesFilters(store({ ratingAvg: 4.8 }), ['top_rated'])).toBe(true);
    // Sin reseñas no es "4.5 o más", aunque el promedio guardado diga 5.
    expect(matchesFilters(store({ ratingAvg: 5, ratingCount: 0 }), ['top_rated'])).toBe(false);
    expect(matchesFilters(store({ minOrderAmount: { amount: 0 } }), ['no_minimum'])).toBe(true);
    expect(matchesFilters(store({ promoLabel: '2x1' }), ['offers'])).toBe(true);
    expect(matchesFilters(store({ estimatedDeliveryFee: { amount: 0 } }), ['free_delivery', 'offers'])).toBe(false);
  });
});

describe('openFirst', () => {
  it('pone los abiertos adelante sin reordenar cada grupo', () => {
    const rows = [
      { id: 'a', open: false },
      { id: 'b', open: true },
      { id: 'c', open: false },
      { id: 'd', open: true },
    ];
    expect(openFirst(rows, (r) => r.open).map((r) => r.id)).toEqual(['b', 'd', 'a', 'c']);
  });
});
