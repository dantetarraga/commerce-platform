import { Bike, Store } from 'lucide-react'
import { Button } from '@/components/ui/button'

interface NotPartnerNoticeProps {
  isCourier: boolean
  onRetry: () => void
}

export function NotPartnerNotice({ isCourier, onRetry }: NotPartnerNoticeProps) {
  const Icon = isCourier ? Bike : Store
  return (
    <div className='space-y-6' role='status'>
      <div className='corner-exit-s bg-primary-soft text-primary flex size-14 items-center justify-center'>
        <Icon className='size-7' aria-hidden />
      </div>
      {isCourier ? (
        <div className='space-y-2'>
          <h2 className='text-2xl font-semibold'>Tus entregas están en la app</h2>
          <p className='text-muted-foreground'>
            Los repartidores trabajan desde Apamuy Socios: ahí te conectas, tomas pedidos y ves tu
            caja del día. Este panel es para los negocios y el equipo Apamuy.
          </p>
        </div>
      ) : (
        <div className='space-y-2'>
          <h2 className='text-2xl font-semibold'>Aún no eres socio de Apamuy</h2>
          <p className='text-muted-foreground'>
            Este panel es para los negocios afiliados y el equipo Apamuy. Si quieres vender o
            repartir con nosotros, escríbenos y te damos de alta.
          </p>
        </div>
      )}
      <Button variant='outline' className='w-full' onClick={onRetry}>
        Usar otro número
      </Button>
    </div>
  )
}
