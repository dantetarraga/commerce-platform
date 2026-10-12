import type { QueryClient } from '@tanstack/react-query'
import { http, realtime, setupAuthInterceptors } from '@/app/api'
import { getAccessToken, hasSession, refreshAccessToken } from '@/features/auth'

export function setupHttp(queryClient: QueryClient) {
  realtime.configure({ getAccessToken, refreshAccessToken })
  return setupAuthInterceptors(http, {
    getAccessToken,
    canRefresh: hasSession,
    refreshAccessToken,
    // La sesión ya quedó anónima: `setupSessionSync` hace que las guardas redirijan.
    onAuthFailure: () => queryClient.clear(),
  })
}
