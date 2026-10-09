import { QueryErrorResetBoundary } from '@tanstack/react-query'
import { type ReactNode, Suspense } from 'react'
import { ErrorBoundary } from 'react-error-boundary'
import { ErrorState } from './error-state'
import { LoadingState } from './query-feedback'

interface QueryBoundaryProps {
  children: ReactNode
  fallback?: ReactNode
  className?: string
}

/**
 * Límite de carga y error para los componentes que usan `useSuspenseQuery`. Si una
 * sección falla, el resto de la página sigue funcionando.
 */
export function QueryBoundary({
  children,
  fallback = <LoadingState />,
  className,
}: QueryBoundaryProps) {
  return (
    <QueryErrorResetBoundary>
      {({ reset }) => (
        <ErrorBoundary
          onReset={reset}
          fallbackRender={({ error, resetErrorBoundary }) => (
            <ErrorState error={error} onRetry={resetErrorBoundary} className={className} />
          )}
        >
          <Suspense fallback={fallback}>{children}</Suspense>
        </ErrorBoundary>
      )}
    </QueryErrorResetBoundary>
  )
}
