import { lazyRouteComponent } from '@tanstack/react-router'

export const partnersRoute = {
  path: 'partners',
  component: lazyRouteComponent(() => import('../pages/partners.page'), 'PartnersPage'),
} as const
