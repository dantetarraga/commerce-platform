/**
 * Todas las claves de React Query. Una mutación de un feature puede invalidar datos de
 * otro (crear un negocio cambia la ficha de su dueño en Socios), así que viven juntas.
 */
export const queryKeys = {
  cities: () => ['cities'] as const,
  adminCities: () => ['admin', 'cities'] as const,
  ownStores: () => ['merchant', 'stores'] as const,
  partnerSummary: (date: string) => ['merchant', 'summary', date] as const,
  partnerReport: (filters: object) => ['merchant', 'report', filters] as const,
  partnerSettlement: (filters: object) => ['merchant', 'settlement', filters] as const,
  cash: (filters: object) => ['admin', 'cash', filters] as const,
  categories: () => ['categories'] as const,
  stores: {
    all: () => ['admin', 'stores'] as const,
    list: () => ['admin', 'stores', 'list'] as const,
    detail: (id: string) => ['admin', 'stores', 'detail', id] as const,
  },
  coupons: () => ['admin', 'coupons'] as const,
  promotions: {
    all: () => ['admin', 'promotions'] as const,
    byCity: (cityId: string) => ['admin', 'promotions', cityId || 'all'] as const,
  },
  orders: {
    all: () => ['admin', 'orders'] as const,
    board: (cityId: string) => ['admin', 'orders', 'board', cityId || 'all'] as const,
    history: (filters: object) => ['admin', 'orders', 'history', filters] as const,
    detail: (id: string) => ['admin', 'orders', 'detail', id] as const,
  },
  partners: {
    all: () => ['admin', 'partners'] as const,
    byPhone: (phone: string) => ['admin', 'partners', phone] as const,
  },
}
