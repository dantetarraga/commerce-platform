import type { ErrorComponentProps } from '@tanstack/react-router'
import { WifiOff } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { EmptyState } from './empty-state'

export function RouteError({ error, reset }: ErrorComponentProps) {
  const message =
    error instanceof Error && error.name === 'ApiError'
      ? error.message
      : 'Algo salió mal al cargar esta sección.'
  return (
    <div className='mx-auto max-w-xl px-5 py-16'>
      <EmptyState
        icon={WifiOff}
        title='No pudimos cargar esta sección'
        description={message}
        action={<Button onClick={reset}>Reintentar</Button>}
      />
    </div>
  )
}
