/**
 * Todas las claves de React Query. Una mutación de un feature puede invalidar datos de
 * otro (crear un negocio cambia la ficha de su dueño en Socios), así que viven juntas.
 */
export const queryKeys = {
  cities: () => ['cities'] as const,
  categories: () => ['categories'] as const,
  stores: {
    all: () => ['admin', 'stores'] as const,
    list: () => ['admin', 'stores', 'list'] as const,
    detail: (id: string) => ['admin', 'stores', 'detail', id] as const,
  },
  partners: {
    all: () => ['admin', 'partners'] as const,
    byPhone: (phone: string) => ['admin', 'partners', phone] as const,
  },
}
