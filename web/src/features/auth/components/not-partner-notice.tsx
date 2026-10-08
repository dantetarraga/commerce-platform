import { Store } from 'lucide-react'
import { Button } from '@/components/ui/button'

export function NotPartnerNotice({ onRetry }: { onRetry: () => void }) {
  return (
    <div className='space-y-6' role='status'>
      <div className='corner-exit-s bg-primary-soft text-primary flex size-14 items-center justify-center'>
        <Store className='size-7' aria-hidden />
      </div>
      <div className='space-y-2'>
        <h2 className='text-2xl font-semibold'>Aún no eres socio de Apamuy</h2>
        <p className='text-muted-foreground'>
          Este panel es para el equipo de Apamuy y los negocios afiliados. Si quieres vender con
          nosotros, escríbenos y te damos de alta.
        </p>
      </div>
      <Button variant='outline' className='w-full' onClick={onRetry}>
        Usar otro número
      </Button>
    </div>
  )
}
