import type { QueryClient } from '@tanstack/react-query'
import { createRootRouteWithContext, createRoute, createRouter } from '@tanstack/react-router'
import { NotFound } from '@/components/shared/not-found'
import { LoadingState } from '@/components/shared/query-feedback'
import { RouteError } from '@/components/shared/route-error'
import { loginRoute } from '@/features/auth'
import { cashRoute } from '@/features/cash'
import {
  catalogRoute,
  partnerMenuRoute,
  partnerStoreRoute,
  storeDetailRoute,
} from '@/features/catalog'
import { citiesRoute } from '@/features/cities'
import { adminHomeRoute } from '@/features/home'
import { accountDeletionRoute, landingRoute, privacyRoute, termsRoute } from '@/features/landing'
import { marketingRoute } from '@/features/marketing'
import { ordersRoute } from '@/features/orders'
import { partnerHomeRoute, partnerReportsRoute, partnerSettlementRoute } from '@/features/partner'
import { partnersRoute } from '@/features/partners'
import { AdminLayout } from '@/layouts/admin-layout'
import { AuthLayout } from '@/layouts/auth-layout'
import { MerchantLayout } from '@/layouts/merchant-layout'
import { RootLayout } from '@/layouts/root-layout'
import { redirectIfSignedIn, requireRole } from './guards'

export interface RouterContext {
  queryClient: QueryClient
}

const rootRoute = createRootRouteWithContext<RouterContext>()({
  component: RootLayout,
  notFoundComponent: NotFound,
  errorComponent: RouteError,
})

// La portada es pública: quien ya inició sesión entra a su panel desde "Ingresar".
const landing = createRoute({ getParentRoute: () => rootRoute, ...landingRoute })
const accountDeletion = createRoute({ getParentRoute: () => rootRoute, ...accountDeletionRoute })
const privacy = createRoute({ getParentRoute: () => rootRoute, ...privacyRoute })
const terms = createRoute({ getParentRoute: () => rootRoute, ...termsRoute })

const authLayoutRoute = createRoute({
  getParentRoute: () => rootRoute,
  id: 'auth',
  component: AuthLayout,
  beforeLoad: redirectIfSignedIn,
})
const login = createRoute({ getParentRoute: () => authLayoutRoute, ...loginRoute })

const adminLayoutRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: 'admin',
  component: AdminLayout,
  beforeLoad: requireRole('ADMIN'),
})
const adminHome = createRoute({ getParentRoute: () => adminLayoutRoute, ...adminHomeRoute })
const partners = createRoute({ getParentRoute: () => adminLayoutRoute, ...partnersRoute })
const catalog = createRoute({ getParentRoute: () => adminLayoutRoute, ...catalogRoute })
const storeDetail = createRoute({ getParentRoute: () => adminLayoutRoute, ...storeDetailRoute })
const marketing = createRoute({ getParentRoute: () => adminLayoutRoute, ...marketingRoute })
const cities = createRoute({ getParentRoute: () => adminLayoutRoute, ...citiesRoute })
const orders = createRoute({ getParentRoute: () => adminLayoutRoute, ...ordersRoute })
const cash = createRoute({ getParentRoute: () => adminLayoutRoute, ...cashRoute })

const merchantLayoutRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: 'partner',
  component: MerchantLayout,
  beforeLoad: requireRole('MERCHANT'),
})
const partnerHome = createRoute({ getParentRoute: () => merchantLayoutRoute, ...partnerHomeRoute })
const partnerStore = createRoute({
  getParentRoute: () => merchantLayoutRoute,
  ...partnerStoreRoute,
})
const partnerMenu = createRoute({ getParentRoute: () => merchantLayoutRoute, ...partnerMenuRoute })
const partnerReports = createRoute({
  getParentRoute: () => merchantLayoutRoute,
  ...partnerReportsRoute,
})
const partnerSettlement = createRoute({
  getParentRoute: () => merchantLayoutRoute,
  ...partnerSettlementRoute,
})

const routeTree = rootRoute.addChildren([
  landing,
  accountDeletion,
  privacy,
  terms,
  authLayoutRoute.addChildren([login]),
  adminLayoutRoute.addChildren([
    adminHome,
    partners,
    catalog,
    storeDetail,
    marketing,
    cities,
    orders,
    cash,
  ]),
  merchantLayoutRoute.addChildren([
    partnerHome,
    partnerStore,
    partnerMenu,
    partnerReports,
    partnerSettlement,
  ]),
])

export function createAppRouter(queryClient: QueryClient) {
  return createRouter({
    routeTree,
    context: { queryClient },
    defaultPreload: 'intent',
    // La frescura la decide React Query; el router siempre le pregunta.
    defaultPreloadStaleTime: 0,
    // Error y carga de una página se muestran dentro de su layout, con el menú a mano.
    defaultErrorComponent: RouteError,
    defaultPendingComponent: () => <LoadingState />,
    scrollRestoration: true,
  })
}

export type AppRouter = ReturnType<typeof createAppRouter>

declare module '@tanstack/react-router' {
  interface Register {
    router: AppRouter
  }
}
