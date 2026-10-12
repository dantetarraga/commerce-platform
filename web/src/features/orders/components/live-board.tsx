import { useQueryClient, useSuspenseQuery } from '@tanstack/react-query'
import { BellRing } from 'lucide-react'
import { useState } from 'react'
import { toast } from 'sonner'
import { queryKeys } from '@/app/api'
import { StatTile } from '@/components/shared/stat-tile'
import { Button } from '@/components/ui/button'
import { useAttentionAlert } from '@/hooks/use-attention-alert'
import { useRealtimeEvent } from '@/hooks/use-realtime-event'
import { useRealtimeReconnect, useRealtimeStatus } from '@/hooks/use-realtime-status'
import { formatMoney } from '@/lib/money'
import { BOARD_COLUMN_LABEL, type AdminOrder, type OrderStatus } from '../model/orders'
import { ordersBoardQuery } from '../queries/orders.queries'
import { OrderCard } from './order-card'

interface OrderChanged {
  orderId: string
  status: OrderStatus
  cityId: string
}

const lateMessage = (count: number) =>
  count === 1
    ? '1 pedido lleva 3 minutos o más sin respuesta. Llama al negocio.'
    : `${count} pedidos llevan 3 minutos o más sin respuesta. Llama al negocio.`

/** Pide permiso para avisar con la pestaña de fondo; solo se puede pedir con un clic. */
function BrowserAlertsPrompt() {
  const [permission, setPermission] = useState(() =>
    'Notification' in window ? Notification.permission : 'denied',
  )
  if (permission !== 'default') return null
  return (
    <div className='bg-primary-soft flex flex-wrap items-center justify-between gap-3 rounded-lg px-4 py-3 text-sm'>
      <p>Activa los avisos para enterarte de un pedido atrasado aunque estés en otra pestaña.</p>
      <Button
        size='sm'
        variant='outline'
        onClick={() => {
          Notification.requestPermission()
            .then(setPermission)
            .catch(() => undefined)
        }}
      >
        Activar avisos
      </Button>
    </div>
  )
}

/** Pedidos en curso en cuatro columnas, al día por WebSocket. Suspende mientras carga. */
export function LiveBoard({
  cityId,
  onOpen,
}: {
  cityId: string
  onOpen: (order: AdminOrder) => void
}) {
  const { data: board } = useSuspenseQuery(ordersBoardQuery(cityId))
  const queryClient = useQueryClient()

  useRealtimeEvent<OrderChanged>('admin.orders.changed', (event) => {
    if (cityId && event.cityId !== cityId) return
    void queryClient.invalidateQueries({ queryKey: queryKeys.orders.all() })
    if (event.status === 'RECEIVED') toast.info('Entró un pedido nuevo', { id: event.orderId })
  })
  // Lo que cambió con el socket caído no llegó: se vuelve a pedir todo.
  useRealtimeReconnect(() => {
    void queryClient.invalidateQueries({ queryKey: queryKeys.orders.all() })
  })
  const live = useRealtimeStatus()
  useAttentionAlert(board.lateCount, lateMessage)

  return (
    <div className='space-y-6'>
      {live === 'reconnecting' && (
        <p
          role='status'
          className='bg-secondary text-muted-foreground rounded-lg px-4 py-2 text-sm'
        >
          Sin conexión en vivo. Reintentando; mientras, el tablero se actualiza cada 30 segundos.
        </p>
      )}
      <BrowserAlertsPrompt />
      {board.lateCount > 0 && (
        <div
          role='alert'
          className='border-destructive bg-destructive/5 flex items-center gap-3 rounded-lg border p-4'
        >
          <BellRing className='text-destructive size-5 shrink-0' aria-hidden />
          <p className='text-sm'>
            <span className='font-semibold'>
              {board.lateCount === 1
                ? '1 pedido lleva 3 minutos o más sin respuesta.'
                : `${board.lateCount} pedidos llevan 3 minutos o más sin respuesta.`}
            </span>{' '}
            Llama al negocio: a los 8 minutos Apamuy los cancela y avisa al cliente.
          </p>
        </div>
      )}
      <div className='grid grid-cols-2 gap-3 md:grid-cols-4'>
        <StatTile label='Pedidos hoy' value={board.today.placed} />
        <StatTile label='Entregados' value={board.today.delivered} />
        <StatTile label='Cancelados' value={board.today.cancelled} />
        <StatTile label='Vendido hoy' value={formatMoney(board.today.sales)} />
      </div>
      <div className='grid gap-4 md:grid-cols-2 xl:grid-cols-4'>
        {board.columns.map((column) => (
          <section
            key={column.key}
            aria-labelledby={`column-${column.key}`}
            className='bg-secondary/50 space-y-3 rounded-xl p-3'
          >
            <header className='flex items-baseline justify-between gap-2 px-1'>
              <div>
                <h2 id={`column-${column.key}`} className='font-semibold'>
                  {BOARD_COLUMN_LABEL[column.key].title}
                </h2>
                <p className='text-muted-foreground text-xs'>
                  {BOARD_COLUMN_LABEL[column.key].hint}
                </p>
              </div>
              <span className='font-display text-xl font-semibold tabular-nums'>
                {column.count}
              </span>
            </header>
            {column.items.length === 0 ? (
              <p className='text-muted-foreground px-1 py-6 text-center text-sm'>Sin pedidos</p>
            ) : (
              <ul className='space-y-2'>
                {column.items.map((order) => (
                  <li key={order.id}>
                    <OrderCard order={order} onOpen={onOpen} />
                  </li>
                ))}
              </ul>
            )}
          </section>
        ))}
      </div>
    </div>
  )
}
