/** Filtros rápidos de la lista de negocios (`?filters=open_now,free_delivery`). */
export const STORE_FILTERS = ['open_now', 'free_delivery', 'top_rated', 'no_minimum', 'offers'] as const;
export type StoreFilter = (typeof STORE_FILTERS)[number];

/** Calificación mínima de `top_rated`. */
export const TOP_RATED_MIN = 4.5;

/** Lo que miran los filtros de un resumen de negocio. */
export interface FilterableStore {
  isOpenNow: boolean;
  estimatedDeliveryFee: { amount: number };
  minOrderAmount: { amount: number };
  ratingAvg: number;
  ratingCount: number;
  promoLabel: string | null;
}

function accepts(store: FilterableStore, filter: StoreFilter): boolean {
  switch (filter) {
    case 'open_now':
      return store.isOpenNow;
    case 'free_delivery':
      return store.estimatedDeliveryFee.amount === 0;
    case 'top_rated':
      return store.ratingCount > 0 && store.ratingAvg >= TOP_RATED_MIN;
    case 'no_minimum':
      return store.minOrderAmount.amount === 0;
    case 'offers':
      return store.promoLabel !== null;
  }
}

/** Pasa todos los filtros (sin filtros, todos). */
export function matchesFilters(store: FilterableStore, filters: readonly StoreFilter[]): boolean {
  return filters.every((filter) => accepts(store, filter));
}

/** Los abiertos primero, sin cambiar el orden dentro de cada grupo. */
export function openFirst<T>(rows: readonly T[], isOpen: (row: T) => boolean): T[] {
  return [...rows.filter(isOpen), ...rows.filter((row) => !isOpen(row))];
}
