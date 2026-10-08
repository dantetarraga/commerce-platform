import type { QueryClient } from '@tanstack/react-query'
import { http, setupAuthInterceptors } from '@/api'
import { refreshAccessToken, useSessionStore } from '@/features/auth'
import type { AppRouter } from '../router/router'

export function setupHttp(queryClient: QueryClient, router: AppRouter) {
  return setupAuthInterceptors(http, {
    getAccessToken: () => useSessionStore.getState().accessToken,
    canRefresh: () => useSessionStore.getState().refreshToken !== null,
    refreshAccessToken,
    onAuthFailure: () => {
      queryClient.clear()
      void router.navigate({ to: '/ingresar', search: { redirect: router.state.location.href } })
    },
  })
}
