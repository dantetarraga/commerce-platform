import { useSuspenseInfiniteQuery } from '@tanstack/react-query'
import { ClipboardList } from 'lucide-react'
import { EmptyState } from '@/components/shared/empty-state'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { dateTime } from '@/lib/datetime'
import { formatMoney } from '@/lib/money'
import type { OrdersHistoryFilters } from '../actions/orders.actions'
import { ORDER_STATUS_LABEL, PAYMENT_LABEL, type AdminOrder } from '../model/orders'
import { ordersHistoryQuery } from '../queries/orders.queries'

/** Pedidos de un día con sus filtros, de 30 en 30. Suspende mientras carga. */
export function OrdersHistory({
  filters,
  onOpen,
}: {
  filters: OrdersHistoryFilters
  onOpen: (order: AdminOrder) => void
}) {
  const { data, hasNextPage, fetchNextPage, isFetchingNextPage } = useSuspenseInfiniteQuery(
    ordersHistoryQuery(filters),
  )
  const orders = data.pages.flatMap((page) => page.items)
  if (orders.length === 0) {
    return (
      <EmptyState
        icon={ClipboardList}
        title='Sin pedidos'
        description='No hay pedidos con estos filtros. Prueba con otro día o estado.'
      />
    )
  }
  return (
    <div className='space-y-4'>
      <ul className='divide-y'>
        {orders.map((order) => (
          <li key={order.id}>
            <button
              type='button'
              onClick={() => onOpen(order)}
              className='hover:bg-secondary/60 grid w-full gap-2 rounded-md px-2 py-3 text-left text-sm sm:grid-cols-[auto_minmax(0,1fr)_auto_auto] sm:items-center sm:gap-4'
            >
              <span className='font-mono font-semibold'>{order.code}</span>
              <span className='min-w-0'>
                <span className='block truncate font-semibold'>{order.store.name}</span>
                <span className='text-muted-foreground block truncate'>
                  {dateTime.formatTime(order.placedAt)} · {order.customer.name}
                </span>
              </span>
              <StatusBadge active={order.status === 'DELIVERED'}>
                {ORDER_STATUS_LABEL[order.status]}
              </StatusBadge>
              <span className='tabular-nums sm:text-right'>
                {formatMoney(order.total)}
                <span className='text-muted-foreground block text-xs'>
                  {PAYMENT_LABEL[order.payment.type]}
                </span>
              </span>
            </button>
          </li>
        ))}
      </ul>
      {hasNextPage && (
        <div className='flex justify-center'>
          <Button
            variant='outline'
            disabled={isFetchingNextPage}
            onClick={() => {
              void fetchNextPage()
            }}
          >
            {isFetchingNextPage ? 'Cargando…' : 'Ver más pedidos'}
          </Button>
        </div>
      )}
    </div>
  )
}
