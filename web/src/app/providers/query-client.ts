import { QueryClient } from '@tanstack/react-query'
import { ApiError } from '@/api'

const shouldRetry = (failureCount: number, error: unknown) =>
  failureCount < 2 && error instanceof ApiError && error.isRetriable

export function createQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { staleTime: 30_000, retry: shouldRetry, refetchOnWindowFocus: true },
      mutations: { retry: false },
    },
  })
}
