import { type ErrorComponentProps, Link, useRouter } from '@tanstack/react-router'
import { House } from 'lucide-react'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { ErrorState } from './error-state'

export function RouteError({ error, reset }: ErrorComponentProps) {
  const router = useRouter()
  const [isRetrying, setIsRetrying] = useState(false)

  async function handleRetry() {
    setIsRetrying(true)
    // Sin invalidar, el router reusaría el loader que falló.
    await router.invalidate()
    reset()
    setIsRetrying(false)
  }

  return (
    <div className='mx-auto max-w-2xl px-5 py-16'>
      <ErrorState
        error={error}
        isRetrying={isRetrying}
        onRetry={() => {
          void handleRetry()
        }}
        action={
          <Button asChild variant='outline'>
            <Link to='/'>
              <House aria-hidden />
              Volver al inicio
            </Link>
          </Button>
        }
      />
    </div>
  )
}
