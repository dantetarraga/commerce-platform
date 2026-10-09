import type { QueryClient } from '@tanstack/react-query'
import { lazyRouteComponent } from '@tanstack/react-router'
import { adminStoresQuery, citiesQuery } from '@/app/api/lookups'
import { categoriesQuery, storeQuery } from '../queries/catalog.queries'

interface LoaderArgs {
  context: { queryClient: QueryClient }
}

// Los loaders inician la carga al navegar (o al pasar el mouse por el enlace) sin esperarla:
// la página se pinta al instante y cada bloque muestra su fallback hasta tener datos.
export const catalogRoute = {
  path: 'catalog',
  loader: ({ context: { queryClient } }: LoaderArgs) => {
    void queryClient.prefetchQuery(adminStoresQuery)
    void queryClient.prefetchQuery(citiesQuery)
    void queryClient.prefetchQuery(categoriesQuery)
  },
  component: lazyRouteComponent(() => import('../pages/catalog.page'), 'CatalogPage'),
} as const

export const storeDetailRoute = {
  path: 'catalog/$storeId',
  loader: ({ context: { queryClient }, params }: LoaderArgs & { params: { storeId: string } }) => {
    void queryClient.prefetchQuery(storeQuery(params.storeId))
  },
  component: lazyRouteComponent(() => import('../pages/store-detail.page'), 'StoreDetailPage'),
} as const
