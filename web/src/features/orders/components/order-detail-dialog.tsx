import { useSuspenseQuery } from '@tanstack/react-query'
import { Phone } from 'lucide-react'
import { useState, type ReactNode } from 'react'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { dateTime } from '@/lib/datetime'
import { formatMoney } from '@/lib/money'
import {
  cancelledByLabel,
  isFinal,
  ORDER_STATUS_LABEL,
  PAYMENT_LABEL,
  type AdminOrder,
} from '../model/orders'
import { orderQuery } from '../queries/orders.queries'
import { CancelOrderForm } from './cancel-order-form'

/** Detalle de un pedido sobre el tablero o el historial. */
export function OrderDetailDialog({ order, onClose }: { order: AdminOrder; onClose: () => void }) {
  return (
    <EditorDialog
      title={`Pedido ${order.code}`}
      description={`${order.store.name} · ${dateTime.formatDateTime(order.placedAt)}`}
      onClose={onClose}
    >
      <QueryBoundary fallback={<Skeleton className='h-64 w-full' />}>
        <OrderDetail initial={order} onClose={onClose} />
      </QueryBoundary>
    </EditorDialog>
  )
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className='space-y-2'>
      <h3 className='text-muted-foreground text-xs font-bold tracking-widest uppercase'>{title}</h3>
      {children}
    </section>
  )
}

function CallLink({ phone, label }: { phone: string | null; label: string }) {
  if (!phone) return null
  return (
    <Button asChild variant='outline' size='sm'>
      <a href={`tel:${phone}`} aria-label={`${label}: ${phone}`}>
        <Phone aria-hidden />
        {phone}
      </a>
    </Button>
  )
}

function OrderDetail({ initial, onClose }: { initial: AdminOrder; onClose: () => void }) {
  // Se pinta al instante con lo del tablero y se actualiza con el detalle.
  const { data: order } = useSuspenseQuery({
    ...orderQuery(initial.id),
    initialData: initial,
    initialDataUpdatedAt: 0,
  })
  const [cancelling, setCancelling] = useState(false)
  return (
    <div className='space-y-6 text-sm'>
      <div className='flex flex-wrap items-center gap-2'>
        <StatusBadge active={order.status === 'DELIVERED'}>
          {ORDER_STATUS_LABEL[order.status]}
        </StatusBadge>
        {order.alert === 'late' && (
          <span className='text-destructive font-semibold'>
            {order.waitingMinutes} min sin respuesta del negocio
          </span>
        )}
      </div>
      {order.status === 'CANCELLED' && (
        <p className='bg-secondary rounded-lg p-3'>
          Cancelado por {cancelledByLabel(order)}
          {order.cancelReason && `: ${order.cancelReason}`}
        </p>
      )}
      <div className='grid gap-6 sm:grid-cols-2'>
        <Section title='Negocio'>
          <p className='font-semibold'>{order.store.name}</p>
          <p className='text-muted-foreground'>{order.pickup.address}</p>
          <CallLink phone={order.pickup.phone} label='Llamar al negocio' />
        </Section>
        <Section title='Cliente'>
          <p className='font-semibold'>{order.customer.name}</p>
          <p className='text-muted-foreground'>
            {order.address.street}
            {order.address.reference && ` · ${order.address.reference}`}
          </p>
          <CallLink phone={order.customer.phone} label='Llamar al cliente' />
        </Section>
      </div>
      <Section title='Productos'>
        <ul className='divide-y'>
          {order.lines.map((line, index) => (
            <li key={index} className='flex justify-between gap-4 py-2'>
              <span>
                {line.quantity} × {line.name}
                {line.description && (
                  <span className='text-muted-foreground block text-xs'>{line.description}</span>
                )}
                {line.notes && <span className='text-primary block text-xs'>“{line.notes}”</span>}
              </span>
              <span className='tabular-nums'>{formatMoney(line.total)}</span>
            </li>
          ))}
        </ul>
        <dl className='space-y-1 border-t pt-2'>
          {[
            { label: 'Delivery', amount: order.deliveryFee },
            { label: 'Descuento', amount: order.discount },
            { label: 'Propina', amount: order.tip },
          ]
            .filter(({ label, amount }) => label === 'Delivery' || amount.amount > 0)
            .map(({ label, amount }) => (
              <div key={label} className='text-muted-foreground flex justify-between'>
                <dt>{label}</dt>
                <dd className='tabular-nums'>{formatMoney(amount)}</dd>
              </div>
            ))}
          <div className='flex justify-between font-semibold'>
            <dt>Total · {PAYMENT_LABEL[order.payment.type]}</dt>
            <dd className='tabular-nums'>{formatMoney(order.total)}</dd>
          </div>
        </dl>
        {order.couponCode && (
          <p className='text-muted-foreground text-xs'>Cupón {order.couponCode}</p>
        )}
      </Section>
      <Section title='Seguimiento'>
        <ol className='space-y-1'>
          {order.events.map((event, index) => (
            <li key={index} className='flex justify-between gap-4'>
              <span>{ORDER_STATUS_LABEL[event.status]}</span>
              <span className='text-muted-foreground tabular-nums'>
                {dateTime.formatTime(event.at)}
              </span>
            </li>
          ))}
        </ol>
        {order.courier && <p className='text-muted-foreground'>Repartidor: {order.courier.name}</p>}
      </Section>
      {!isFinal(order.status) &&
        (cancelling ? (
          <CancelOrderForm
            orderId={order.id}
            onDone={onClose}
            onBack={() => setCancelling(false)}
          />
        ) : (
          <div className='flex justify-end border-t pt-4'>
            <Button variant='ghost' onClick={() => setCancelling(true)}>
              Cancelar pedido
            </Button>
          </div>
        ))}
    </div>
  )
}
