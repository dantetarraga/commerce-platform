import { Clock } from 'lucide-react'
import { dateTime } from '@/lib/datetime'
import { cn } from '@/lib/cn'
import { formatMoney } from '@/lib/money'
import { PAYMENT_LABEL, type AdminOrder } from '../model/orders'

interface OrderCardProps {
  order: AdminOrder
  onOpen: (order: AdminOrder) => void
}

/** Pedido en el tablero. Si el negocio no responde hace 3 minutos, se resalta. */
export function OrderCard({ order, onOpen }: OrderCardProps) {
  const late = order.alert === 'late'
  return (
    <button
      type='button'
      onClick={() => onOpen(order)}
      className={cn(
        'bg-card hover:border-primary focus-visible:ring-ring w-full space-y-2 rounded-lg border p-3 text-left text-sm transition-colors focus-visible:ring-2 focus-visible:outline-none',
        late && 'border-destructive bg-destructive/5',
      )}
    >
      <div className='flex items-center justify-between gap-2'>
        <span className='font-mono font-semibold'>{order.code}</span>
        {order.waitingMinutes !== null ? (
          <span
            className={cn(
              'inline-flex items-center gap-1 text-xs font-semibold tabular-nums',
              late ? 'text-destructive' : 'text-muted-foreground',
            )}
          >
            <Clock className='size-3.5' aria-hidden />
            {late && <span className='sr-only'>Sin respuesta: </span>}
            {order.waitingMinutes} min
          </span>
        ) : (
          <span className='text-muted-foreground text-xs tabular-nums'>
            {dateTime.formatTime(order.placedAt)}
          </span>
        )}
      </div>
      <p className='truncate font-semibold'>{order.store.name}</p>
      <p className='text-muted-foreground truncate'>
        {order.customer.name} · {order.address.street}
      </p>
      <div className='flex items-center justify-between gap-2'>
        <span className='font-semibold tabular-nums'>{formatMoney(order.total)}</span>
        <span className='text-muted-foreground text-xs'>
          {PAYMENT_LABEL[order.payment.type]}
          {order.courier && ` · ${order.courier.name}`}
        </span>
      </div>
      {order.scheduledFor && (
        <p className='text-primary text-xs font-semibold'>
          Programado para {dateTime.formatTime(order.scheduledFor)}
        </p>
      )}
    </button>
  )
}
