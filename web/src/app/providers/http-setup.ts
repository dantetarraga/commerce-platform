import type { QueryClient } from '@tanstack/react-query'
import { http, setupAuthInterceptors } from '@/app/api'
import { getAccessToken, hasRefreshToken, refreshAccessToken } from '@/features/auth'

export function setupHttp(queryClient: QueryClient) {
  return setupAuthInterceptors(http, {
    getAccessToken,
    canRefresh: hasRefreshToken,
    refreshAccessToken,
    // La sesión ya quedó anónima: `setupSessionSync` hace que las guardas redirijan.
    onAuthFailure: () => queryClient.clear(),
  })
}
