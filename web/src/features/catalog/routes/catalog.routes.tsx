import { lazyRouteComponent } from '@tanstack/react-router'

export const catalogRoute = {
  path: 'catalog',
  component: lazyRouteComponent(() => import('../pages/catalog.page'), 'CatalogPage'),
} as const
export const storeDetailRoute = {
  path: 'catalog/$storeId',
  component: lazyRouteComponent(() => import('../pages/store-detail.page'), 'StoreDetailPage'),
} as const
