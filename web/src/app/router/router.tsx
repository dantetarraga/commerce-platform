import type { QueryClient } from '@tanstack/react-query'
import { createRootRouteWithContext, createRoute, createRouter } from '@tanstack/react-router'
import { NotFound } from '@/components/shared/not-found'
import { LoadingState } from '@/components/shared/query-feedback'
import { RouteError } from '@/components/shared/route-error'
import { loginRoute } from '@/features/auth'
import { catalogRoute, storeDetailRoute } from '@/features/catalog'
import { adminHomeRoute, merchantHomeRoute } from '@/features/home'
import { landingRoute } from '@/features/landing'
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

const merchantLayoutRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: 'partner',
  component: MerchantLayout,
  beforeLoad: requireRole('MERCHANT'),
})
const merchantHome = createRoute({
  getParentRoute: () => merchantLayoutRoute,
  ...merchantHomeRoute,
})

const routeTree = rootRoute.addChildren([
  landing,
  authLayoutRoute.addChildren([login]),
  adminLayoutRoute.addChildren([adminHome, partners, catalog, storeDetail]),
  merchantLayoutRoute.addChildren([merchantHome]),
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
