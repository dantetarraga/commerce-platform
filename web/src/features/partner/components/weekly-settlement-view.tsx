import { useSuspenseQuery } from '@tanstack/react-query'
import { StatTile } from '@/components/shared/stat-tile'
import { StatusBadge } from '@/components/shared/status-badge'
import { WeekNav } from '@/components/shared/week-nav'
import { dateTime } from '@/lib/datetime'
import { formatMoney } from '@/lib/money'
import { formatRate } from '@/lib/percent'
import type { WeeklySettlement } from '../model/partner'
import { weeklySettlementQuery } from '../queries/partner.queries'

const STATUS: Record<WeeklySettlement['status'], string> = {
  OPEN: 'Semana en curso',
  PENDING: 'Por liquidar',
  PAID: 'Liquidada',
  EMPTY: 'Sin ventas',
}

function balanceText(settlement: WeeklySettlement) {
  if (settlement.owedTo === 'STORE') return 'Apamuy te paga'
  if (settlement.owedTo === 'APAMUY') return 'Le pagas a Apamuy'
  return 'Sin saldo'
}

interface WeeklySettlementViewProps {
  week: string
  storeId: string
  onWeekChange: (week: string) => void
}

/** Liquidación de una semana: vendido − comisión − lo que cobraste tú = saldo. Suspende mientras carga. */
export function WeeklySettlementView({ week, storeId, onWeekChange }: WeeklySettlementViewProps) {
  const { data: settlement } = useSuspenseQuery(weeklySettlementQuery(week, storeId))
  const balance = { ...settlement.balance, amount: Math.abs(settlement.balance.amount) }
  return (
    <div className='space-y-5'>
      <div className='flex flex-wrap items-center justify-between gap-3'>
        <WeekNav week={settlement.week} onChange={onWeekChange} />
        <div className='text-right'>
          <StatusBadge active={settlement.status === 'PAID'}>
            {STATUS[settlement.status]}
          </StatusBadge>
          {settlement.paid && (
            <p className='text-muted-foreground mt-1 text-xs'>
              {dateTime.formatDateTime(settlement.paid.at)}
            </p>
          )}
        </div>
      </div>
      <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
        <StatTile
          label='Vendido'
          value={formatMoney(settlement.sales)}
          hint={`${settlement.delivered} entregas`}
        />
        <StatTile label='Comisión de Apamuy' value={formatMoney(settlement.commission)} />
        <StatTile label='Cobraste tú' value={formatMoney(settlement.collectedByStore)} />
        <StatTile
          label='Saldo'
          value={formatMoney(balance)}
          hint={balanceText(settlement)}
          className={settlement.owedTo === 'STORE' ? 'border-primary' : undefined}
        />
      </div>
      {settlement.orders.length === 0 ? (
        <p className='text-muted-foreground text-sm'>Sin pedidos entregados esta semana.</p>
      ) : (
        <div className='overflow-x-auto'>
          <table className='w-full text-left text-sm'>
            <thead className='text-muted-foreground border-b text-xs'>
              <tr>
                <th scope='col' className='py-2 pr-4'>
                  Pedido
                </th>
                <th scope='col' className='px-4 py-2'>
                  Entregado
                </th>
                <th scope='col' className='px-4 py-2 text-right'>
                  Productos
                </th>
                <th scope='col' className='px-4 py-2 text-right'>
                  Comisión
                </th>
                <th scope='col' className='py-2 pl-4 text-right'>
                  Cobraste tú
                </th>
              </tr>
            </thead>
            <tbody className='divide-y tabular-nums'>
              {settlement.orders.map((order) => (
                <tr key={order.id}>
                  <th scope='row' className='py-2 pr-4 font-semibold'>
                    {order.code}
                  </th>
                  <td className='px-4 py-2'>{dateTime.formatDateTime(order.deliveredAt)}</td>
                  <td className='px-4 py-2 text-right'>{formatMoney(order.subtotal)}</td>
                  <td className='px-4 py-2 text-right'>
                    {formatMoney(order.commission)}
                    <span className='text-muted-foreground block text-xs'>
                      {formatRate(order.rateBps)}
                    </span>
                  </td>
                  <td className='py-2 pl-4 text-right'>{formatMoney(order.collectedByStore)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
