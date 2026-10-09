import { useSuspenseQuery } from '@tanstack/react-query'
import { Banknote, TriangleAlert } from 'lucide-react'
import { EmptyState } from '@/components/shared/empty-state'
import { StatTile } from '@/components/shared/stat-tile'
import { cn } from '@/lib/cn'
import { formatMoney, type Money } from '@/lib/money'
import type { CashFilters } from '../model/cash'
import { cashDayQuery } from '../queries/cash.queries'

/** "−S/ 4.00" en rojo si falta, "S/ 0.00" si cuadra. */
function Difference({ money }: { money: Money }) {
  const short = money.amount < 0
  return (
    <span className={cn('tabular-nums', short && 'text-destructive font-semibold')}>
      {short && '−'}
      {formatMoney({ ...money, amount: Math.abs(money.amount) })}
    </span>
  )
}

/** Rendición del día: totales, repartidores y negocios. Suspende mientras carga. */
export function CashReport({ filters }: { filters: CashFilters }) {
  const { data: cash } = useSuspenseQuery(cashDayQuery(filters))
  if (cash.delivered === 0) {
    return (
      <EmptyState
        icon={Banknote}
        title='Sin entregas este día'
        description='La caja se arma con los pedidos entregados. Prueba con otro día o ciudad.'
      />
    )
  }
  const short = cash.couriers.filter((courier) => courier.difference.amount < 0)
  return (
    <div className='space-y-6'>
      {short.length > 0 && (
        <div
          role='alert'
          className='border-destructive bg-destructive/5 flex items-start gap-3 rounded-lg border p-4 text-sm'
        >
          <TriangleAlert className='text-destructive mt-0.5 size-5 shrink-0' aria-hidden />
          <p>
            <span className='font-semibold'>
              {short.map((courier) => courier.name).join(', ')}{' '}
              {short.length === 1 ? 'tiene' : 'tienen'} cobros por debajo de lo esperado.
            </span>{' '}
            Puede ser un vuelto mal dado o una entrega sin registrar el cobro en la app.
          </p>
        </div>
      )}
      <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
        <StatTile label='Entregas' value={cash.delivered} />
        <StatTile
          label='Cobrado'
          value={formatMoney(cash.collected.total)}
          hint={
            <>
              Esperado {formatMoney(cash.expected)} · diferencia{' '}
              <Difference money={cash.difference} />
            </>
          }
        />
        <StatTile label='Vendido por negocios' value={formatMoney(cash.sales)} />
        <StatTile
          label='Envíos y propinas'
          value={formatMoney({
            ...cash.deliveryFees,
            amount: cash.deliveryFees.amount + cash.tips.amount,
          })}
        />
      </div>
      <section className='corner-exit-m bg-card border p-5'>
        <h2 className='mb-4 text-lg font-semibold'>Repartidores</h2>
        <div className='overflow-x-auto'>
          <table className='w-full text-left text-sm'>
            <thead className='text-muted-foreground border-b text-xs'>
              <tr>
                <th scope='col' className='py-2 pr-4'>
                  Repartidor
                </th>
                <th scope='col' className='px-3 py-2 text-right'>
                  Entregas
                </th>
                <th scope='col' className='px-3 py-2 text-right'>
                  Efectivo
                </th>
                <th scope='col' className='px-3 py-2 text-right'>
                  Yape
                </th>
                <th scope='col' className='px-3 py-2 text-right'>
                  Plin
                </th>
                <th scope='col' className='px-3 py-2 text-right'>
                  Esperado
                </th>
                <th scope='col' className='py-2 pl-3 text-right'>
                  Diferencia
                </th>
              </tr>
            </thead>
            <tbody className='divide-y tabular-nums'>
              {cash.couriers.map((courier) => (
                <tr key={courier.courierId}>
                  <th scope='row' className='py-2 pr-4 text-left font-semibold'>
                    {courier.name}
                    <a
                      href={`tel:${courier.phone}`}
                      className='text-muted-foreground block text-xs font-normal'
                    >
                      {courier.phone}
                    </a>
                  </th>
                  <td className='px-3 py-2 text-right'>{courier.delivered}</td>
                  <td className='px-3 py-2 text-right'>{formatMoney(courier.collected.CASH)}</td>
                  <td className='px-3 py-2 text-right'>{formatMoney(courier.collected.YAPE)}</td>
                  <td className='px-3 py-2 text-right'>{formatMoney(courier.collected.PLIN)}</td>
                  <td className='px-3 py-2 text-right'>{formatMoney(courier.expected)}</td>
                  <td className='py-2 pl-3 text-right'>
                    <Difference money={courier.difference} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
      <section className='corner-exit-m bg-card border p-5'>
        <h2 className='mb-4 text-lg font-semibold'>Negocios</h2>
        <div className='overflow-x-auto'>
          <table className='w-full text-left text-sm'>
            <thead className='text-muted-foreground border-b text-xs'>
              <tr>
                <th scope='col' className='py-2 pr-4'>
                  Negocio
                </th>
                <th scope='col' className='px-3 py-2 text-right'>
                  Entregas
                </th>
                <th scope='col' className='px-3 py-2 text-right'>
                  Vendido
                </th>
                <th scope='col' className='py-2 pl-3 text-right'>
                  Cobrado a sus clientes
                </th>
              </tr>
            </thead>
            <tbody className='divide-y tabular-nums'>
              {cash.stores.map((store) => (
                <tr key={store.storeId}>
                  <th scope='row' className='py-2 pr-4 text-left font-semibold'>
                    {store.name}
                  </th>
                  <td className='px-3 py-2 text-right'>{store.delivered}</td>
                  <td className='px-3 py-2 text-right'>{formatMoney(store.sales)}</td>
                  <td className='py-2 pl-3 text-right'>{formatMoney(store.collected.total)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  )
}
