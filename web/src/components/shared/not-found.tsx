import { Link } from '@tanstack/react-router'
import { Compass } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { EmptyState } from './empty-state'

export function NotFound() {
  return (
    <div className='mx-auto max-w-xl px-5 py-16'>
      <EmptyState
        icon={Compass}
        title='Esta página no existe'
        description='Puede que el enlace esté mal escrito o que la sección todavía no esté lista.'
        action={
          <Button asChild variant='outline'>
            <Link to='/'>Volver al inicio</Link>
          </Button>
        }
      />
    </div>
  )
}
