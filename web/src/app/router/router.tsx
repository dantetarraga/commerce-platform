import type { QueryClient } from '@tanstack/react-query'
import { createRootRouteWithContext, createRoute, createRouter } from '@tanstack/react-router'
import { NotFound } from '@/components/shared/not-found'
import { RouteError } from '@/components/shared/route-error'
import { loginRoute } from '@/features/auth'
import { adminHomeRoute, merchantHomeRoute } from '@/features/home'
import { AdminLayout } from '@/layouts/admin-layout'
import { AuthLayout } from '@/layouts/auth-layout'
import { MerchantLayout } from '@/layouts/merchant-layout'
import { RootLayout } from '@/layouts/root-layout'
import { redirectIfSignedIn, redirectToHome, requireRole } from './guards'

export interface RouterContext {
  queryClient: QueryClient
}

const rootRoute = createRootRouteWithContext<RouterContext>()({
  component: RootLayout,
  notFoundComponent: NotFound,
  errorComponent: RouteError,
})

const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  beforeLoad: redirectToHome,
})

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

const merchantLayoutRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: 'socio',
  component: MerchantLayout,
  beforeLoad: requireRole('MERCHANT'),
})
const merchantHome = createRoute({
  getParentRoute: () => merchantLayoutRoute,
  ...merchantHomeRoute,
})

const routeTree = rootRoute.addChildren([
  indexRoute,
  authLayoutRoute.addChildren([login]),
  adminLayoutRoute.addChildren([adminHome]),
  merchantLayoutRoute.addChildren([merchantHome]),
])

export function createAppRouter(queryClient: QueryClient) {
  return createRouter({
    routeTree,
    context: { queryClient },
    defaultPreload: 'intent',
    defaultPreloadStaleTime: 0,
    scrollRestoration: true,
  })
}

export type AppRouter = ReturnType<typeof createAppRouter>

declare module '@tanstack/react-router' {
  interface Register {
    router: AppRouter
  }
}
