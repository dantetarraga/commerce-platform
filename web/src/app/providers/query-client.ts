import { QueryCache, QueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { ApiError } from '@/app/api'
import { describeError } from '@/lib/errors'

const shouldRetry = (failureCount: number, error: unknown) =>
  failureCount < 2 && error instanceof ApiError && error.isRetriable

export function createQueryClient() {
  return new QueryClient({
    queryCache: new QueryCache({
      // Sin datos, el error lo muestra su QueryBoundary. Con datos, la pantalla sigue
      // mostrando los anteriores y solo falta avisar que no se pudieron actualizar.
      onError: (error, query) => {
        if (query.state.data === undefined) return
        if (error instanceof ApiError && (error.code === 'CANCELED' || error.isUnauthorized)) return
        toast.error('No pudimos actualizar los datos', {
          id: 'background-refetch',
          description: describeError(error).title,
        })
      },
    }),
    defaultOptions: {
      queries: { staleTime: 30_000, retry: shouldRetry, refetchOnWindowFocus: true },
      mutations: { retry: false },
    },
  })
}
