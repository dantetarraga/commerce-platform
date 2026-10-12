import { useSuspenseQuery } from '@tanstack/react-query'
import { HandCoins } from 'lucide-react'
import { useState } from 'react'
import { ConfirmActionDialog, type ConfirmAction } from '@/components/shared/confirm-action-dialog'
import { EmptyState } from '@/components/shared/empty-state'
import { StatTile } from '@/components/shared/stat-tile'
import { StatusBadge } from '@/components/shared/status-badge'
import { WeekNav } from '@/components/shared/week-nav'
import { Button } from '@/components/ui/button'
import { dateTime } from '@/lib/datetime'
import { formatMoney, type Money } from '@/lib/money'
import { markSettlementPaidMutation } from '../mutations/settlements.mutations'
import { settlementWeekQuery } from '../queries/settlements.queries'
import { STATUS_LABEL, type SettlementFilters, type StoreSettlement } from '../model/settlements'

const abs = (money: Money) => ({ ...money, amount: Math.abs(money.amount) })

/** "S/ 120.00 · Apamuy le paga al negocio". */
function Balance({ settlement }: { settlement: StoreSettlement }) {
  if (!settlement.owedTo) {
    return <span className='text-muted-foreground'>{formatMoney(settlement.balance)}</span>
  }
  return (
    <span className='font-semibold'>
      {formatMoney(abs(settlement.balance))}
      <span className='text-muted-foreground block text-xs font-normal'>
        {settlement.owedTo === 'STORE'
          ? 'Apamuy le paga al negocio'
          : 'El negocio le paga a Apamuy'}
      </span>
    </span>
  )
}

interface SettlementWeekReportProps {
  filters: SettlementFilters
  onWeekChange: (week: string) => void
}

/** La semana de cada negocio con su saldo y el botón para marcarla pagada. Suspende mientras carga. */
export function SettlementWeekReport({ filters, onWeekChange }: SettlementWeekReportProps) {
  const { data } = useSuspenseQuery(settlementWeekQuery(filters))
  const [action, setAction] = useState<ConfirmAction | null>(null)

  function handlePay(store: StoreSettlement) {
    const amount = formatMoney(abs(store.balance))
    const direction =
      store.owedTo === 'APAMUY'
        ? `${store.name} le pagó ${amount} a Apamuy`
        : `Apamuy le pagó ${amount} a ${store.name}`
    setAction({
      title: 'Marcar semana como pagada',
      description: `Confirma que ${direction} por la semana del ${dateTime.formatApiDay(data.week.start)} al ${dateTime.formatApiDay(data.week.end)}. Queda registrado quién lo marcó y cuándo.`,
      label: 'Marcar pagada',
      success: 'Semana marcada como pagada.',
      mutation: markSettlementPaidMutation(store.storeId, data.week.start),
    })
  }

  return (
    <div className='space-y-6'>
      <WeekNav week={data.week} onChange={onWeekChange} />
      {data.stores.length === 0 ? (
        <EmptyState
          icon={HandCoins}
          title='Sin ventas esta semana'
          description='La liquidación se arma con los pedidos entregados de lunes a domingo. Prueba con otra semana o ciudad.'
        />
      ) : (
        <>
          <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
            <StatTile
              label='Vendido'
              value={formatMoney(data.totals.sales)}
              hint={`${data.totals.delivered} entregas`}
            />
            <StatTile label='Comisión de Apamuy' value={formatMoney(data.totals.commission)} />
            <StatTile label='A pagar a negocios' value={formatMoney(data.totals.toStores)} />
            <StatTile
              label='A cobrar a negocios'
              value={formatMoney(data.totals.toApamuy)}
              hint={
                data.totals.pendingCount > 0 ? `${data.totals.pendingCount} por pagar` : undefined
              }
            />
          </div>
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
                    <th scope='col' className='px-3 py-2 text-right'>
                      Comisión
                    </th>
                    <th scope='col' className='px-3 py-2 text-right'>
                      Cobró el negocio
                    </th>
                    <th scope='col' className='px-3 py-2 text-right'>
                      Saldo
                    </th>
                    <th scope='col' className='py-2 pl-3 text-right'>
                      Estado
                    </th>
                  </tr>
                </thead>
                <tbody className='divide-y tabular-nums'>
                  {data.stores.map((store) => (
                    <tr key={store.storeId}>
                      <th scope='row' className='py-2 pr-4 text-left font-semibold'>
                        {store.name}
                      </th>
                      <td className='px-3 py-2 text-right'>{store.delivered}</td>
                      <td className='px-3 py-2 text-right'>{formatMoney(store.sales)}</td>
                      <td className='px-3 py-2 text-right'>{formatMoney(store.commission)}</td>
                      <td className='px-3 py-2 text-right'>
                        {formatMoney(store.collectedByStore)}
                      </td>
                      <td className='px-3 py-2 text-right'>
                        <Balance settlement={store} />
                      </td>
                      <td className='py-2 pl-3 text-right'>
                        {store.status === 'PENDING' ? (
                          <Button size='sm' onClick={() => handlePay(store)}>
                            Marcar pagada
                          </Button>
                        ) : (
                          <div className='space-y-1'>
                            <StatusBadge active={store.status === 'PAID'}>
                              {STATUS_LABEL[store.status]}
                            </StatusBadge>
                            {store.paid && (
                              <p className='text-muted-foreground text-xs'>
                                {dateTime.formatDateTime(store.paid.at)}
                                {store.paid.by && ` · ${store.paid.by.name}`}
                              </p>
                            )}
                          </div>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </>
      )}
      {action && <ConfirmActionDialog action={action} onClose={() => setAction(null)} />}
    </div>
  )
}
