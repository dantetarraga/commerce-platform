import { LoaderCircle, RotateCw } from 'lucide-react'
import { ApiError } from '@/app/api'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/cn'
import { describeError } from '@/lib/errors'
import { ErrorIcon, SupportCode } from './error-parts'

export function LoadingState({ label = 'Cargando…' }: { label?: string }) {
  return (
    <p role='status' className='text-muted-foreground flex items-center gap-3 py-8'>
      <LoaderCircle className='size-5 animate-spin' aria-hidden />
      {label}
    </p>
  )
}

interface ErrorNoticeProps {
  error: unknown
  onRetry?: () => void
  isRetrying?: boolean
}

/** Error junto a un formulario o un bloque pequeño. Si no cargó la página entera, `ErrorState`. */
export function ErrorNotice({ error, onRetry, isRetrying = false }: ErrorNoticeProps) {
  if (!error) return null
  const { kind, title, description, requestId, status, retriable } = describeError(error)
  const fields = error instanceof ApiError ? error.details?.fields : undefined
  const messages =
    fields && typeof fields === 'object'
      ? Object.values(fields)
          .flat()
          .filter((v): v is string => typeof v === 'string')
      : []
  return (
    <div
      role='alert'
      className='border-destructive/30 bg-destructive/5 flex gap-3 rounded-lg border p-4 text-sm'
    >
      <ErrorIcon kind={kind} className='text-destructive mt-0.5 size-5' />
      <div className='min-w-0 flex-1 space-y-2'>
        <div className='space-y-0.5'>
          <p className='font-semibold'>{title}</p>
          {description && <p className='text-muted-foreground'>{description}</p>}
        </div>
        {messages.length > 0 && (
          <ul className='list-inside list-disc'>
            {messages.map((message, index) => (
              <li key={index}>{message}</li>
            ))}
          </ul>
        )}
        {onRetry && retriable && (
          <Button type='button' variant='outline' size='sm' onClick={onRetry} disabled={isRetrying}>
            <RotateCw className={cn(isRetrying && 'animate-spin')} aria-hidden />
            {isRetrying ? 'Reintentando…' : 'Reintentar'}
          </Button>
        )}
        {kind === 'server' && <SupportCode status={status} requestId={requestId} />}
      </div>
    </div>
  )
}
