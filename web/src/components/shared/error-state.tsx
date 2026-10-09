import { RotateCw } from 'lucide-react'
import type { ReactNode } from 'react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/cn'
import { describeError } from '@/lib/errors'
import { ErrorIcon, SupportCode } from './error-parts'

interface ErrorStateProps {
  error: unknown
  onRetry?: () => void
  isRetrying?: boolean
  /** Otra salida, p. ej. volver al inicio. */
  action?: ReactNode
  className?: string
}

/** Una página o sección que no pudo cargar. Para errores de un formulario, `ErrorNotice`. */
export function ErrorState({
  error,
  onRetry,
  isRetrying = false,
  action,
  className,
}: ErrorStateProps) {
  const { kind, title, description, requestId, status, retriable } = describeError(error)
  const quiet = kind === 'network' || kind === 'notFound'
  return (
    <section
      role='alert'
      className={cn('corner-exit-l bg-card flex flex-col gap-6 border p-6 md:p-8', className)}
    >
      <div className='flex flex-col items-start gap-4 sm:flex-row'>
        <div
          className={cn(
            'corner-exit-s flex size-12 shrink-0 items-center justify-center',
            quiet ? 'bg-muted text-muted-foreground' : 'bg-destructive/10 text-destructive',
          )}
        >
          <ErrorIcon kind={kind} className='size-6' />
        </div>
        <div className='max-w-prose space-y-1'>
          <h2 className='text-xl font-semibold text-balance'>{title}</h2>
          {description && <p className='text-muted-foreground text-pretty'>{description}</p>}
        </div>
      </div>
      {((onRetry && retriable) || action) && (
        <div className='flex flex-wrap gap-3 sm:pl-16'>
          {onRetry && retriable && (
            <Button type='button' onClick={onRetry} disabled={isRetrying}>
              <RotateCw className={cn(isRetrying && 'animate-spin')} aria-hidden />
              {isRetrying ? 'Reintentando…' : 'Reintentar'}
            </Button>
          )}
          {action}
        </div>
      )}
      <SupportCode status={status} requestId={requestId} className='border-t pt-4' />
    </section>
  )
}
