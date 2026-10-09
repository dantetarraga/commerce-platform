import { useSuspenseQuery } from '@tanstack/react-query'
import type { ReactNode } from 'react'
import { BarChart } from '@/components/shared/bar-chart'
import { RankedBars } from '@/components/shared/ranked-bars'
import { StatTile } from '@/components/shared/stat-tile'
import { changeLabel, hourLabel } from '@/lib/date-range'
import { dateTime } from '@/lib/datetime'
import { formatMoney } from '@/lib/money'
import type { AnalyticsFilters } from '../actions/analytics.actions'
import {
  CANCELLED_BY_LABEL,
  minutesLabel,
  PAYMENT_LABEL,
  WEEKDAY_LABEL,
  type Analytics,
} from '../model/analytics'
import { analyticsQuery } from '../queries/analytics.queries'

function Card({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className='corner-exit-m bg-card space-y-4 border p-5'>
      <h2 className='text-lg font-semibold'>{title}</h2>
      {children}
    </section>
  )
}

const ordersLabel = (count: number) => `${count} ${count === 1 ? 'pedido' : 'pedidos'}`

/** "+12 % vs. 1 oct – 7 oct", o la cifra anterior si no hay base. */
function versus(current: number, previous: number, range: string) {
  const change = changeLabel(current, previous)
  return change ? `${change} ${range}` : `Antes: ${previous}`
}

/** Las cifras del rango y del periodo anterior. Suspende mientras carga. */
export function AnalyticsDashboard({ filters }: { filters: AnalyticsFilters }) {
  const { data } = useSuspenseQuery(analyticsQuery(filters))
  return (
    <div className='space-y-6'>
      <KpiTiles data={data} />
      <Card title='Pedidos por día'>
        {data.kpis.orders === 0 ? (
          <p className='text-muted-foreground text-sm'>Sin pedidos en estas fechas.</p>
        ) : (
          <BarChart
            title='Pedidos por día'
            data={data.byDay.map((day) => ({
              key: day.date,
              label: dateTime.formatApiDay(day.date),
              value: day.orders,
              display: ordersLabel(day.orders),
              detail: `${day.delivered} entregados · ${formatMoney(day.gmv)}${day.cancelled ? ` · ${day.cancelled} cancelados` : ''}`,
            }))}
          />
        )}
      </Card>
      <div className='grid gap-5 lg:grid-cols-2'>
        <Card title='Horas pico'>
          <BarChart
            title='Pedidos por hora'
            data={data.byHour
              .filter((slot) => slot.hour >= 6)
              .map((slot) => ({
                key: String(slot.hour),
                label: hourLabel(slot.hour),
                value: slot.orders,
                display: ordersLabel(slot.orders),
              }))}
          />
        </Card>
        <Card title='Días de la semana'>
          <BarChart
            title='Pedidos por día de la semana'
            // Lunes primero.
            data={[1, 2, 3, 4, 5, 6, 0].map((day) => {
              const orders = data.byWeekday.find((d) => d.dayOfWeek === day)?.orders ?? 0
              return {
                key: String(day),
                label: WEEKDAY_LABEL[day],
                value: orders,
                display: ordersLabel(orders),
              }
            })}
          />
        </Card>
      </div>
      <Card title='Tiempos (mediana)'>
        <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
          <StatTile
            label='Respuesta del negocio'
            value={minutesLabel(data.times.response)}
            hint='Hasta aceptar'
          />
          <StatTile
            label='Preparación'
            value={minutesLabel(data.times.preparation)}
            hint='De aceptado a listo'
          />
          <StatTile
            label='Reparto'
            value={minutesLabel(data.times.delivery)}
            hint='De listo a entregado'
          />
          <StatTile
            label='Total'
            value={minutesLabel(data.times.total)}
            hint='Sin los programados'
          />
        </div>
      </Card>
      <div className='grid gap-5 lg:grid-cols-2'>
        <Card title='Cancelaciones'>
          <RankedBars
            empty='Ningún pedido cancelado.'
            items={data.cancellations.byWho.map((row) => ({
              key: row.who,
              label: CANCELLED_BY_LABEL[row.who],
              value: row.orders,
              display: ordersLabel(row.orders),
            }))}
          />
          {data.cancellations.reasons.length > 0 && (
            <div className='space-y-2 border-t pt-4'>
              <h3 className='text-muted-foreground text-xs font-semibold tracking-wide uppercase'>
                Motivos más dichos
              </h3>
              <ul className='space-y-1 text-sm'>
                {data.cancellations.reasons.map((row) => (
                  <li key={row.reason} className='flex gap-3'>
                    <span className='min-w-0 flex-1 truncate'>{row.reason}</span>
                    <span className='text-muted-foreground tabular-nums'>{row.orders}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </Card>
        <Card title='Cómo pagaron'>
          <RankedBars
            empty='Aún no hay pedidos entregados.'
            items={data.payments.map((row) => ({
              key: row.method,
              label: PAYMENT_LABEL[row.method],
              value: row.amount.amount,
              display: formatMoney(row.amount),
              detail: ordersLabel(row.orders),
            }))}
          />
        </Card>
      </div>
      <div className='grid gap-5 lg:grid-cols-3'>
        <Card title='Negocios que más venden'>
          <RankedBars
            empty='Aún no hay ventas.'
            items={data.topStores.map((store) => ({
              key: store.id,
              label: store.name,
              value: store.sales.amount,
              display: formatMoney(store.sales),
              detail: ordersLabel(store.orders),
            }))}
          />
        </Card>
        <Card title='Lo más pedido'>
          <RankedBars
            empty='Aún no hay ventas.'
            items={data.topProducts.map((product, index) => ({
              key: `${product.name}-${index}`,
              label: product.name,
              value: product.quantity,
              display: `${product.quantity} u.`,
              detail: formatMoney(product.sales),
            }))}
          />
        </Card>
        <Card title='Repartidores'>
          <RankedBars
            empty='Aún no hay entregas.'
            items={data.topCouriers.map((courier) => ({
              key: courier.id,
              label: courier.name,
              value: courier.deliveries,
              display: `${courier.deliveries} entregas`,
              detail: courier.minutes === null ? undefined : `${courier.minutes} min`,
            }))}
          />
        </Card>
      </div>
      {data.coupons.length > 0 && (
        <Card title='Cupones usados'>
          <RankedBars
            empty=''
            items={data.coupons.map((coupon) => ({
              key: coupon.code,
              label: coupon.code,
              value: coupon.orders,
              display: ordersLabel(coupon.orders),
              detail: `−${formatMoney(coupon.discount)}`,
            }))}
          />
        </Card>
      )}
    </div>
  )
}

function KpiTiles({ data }: { data: Analytics }) {
  const { kpis, previous } = data
  const range = `vs. ${dateTime.formatApiDay(data.previousFrom)} – ${dateTime.formatApiDay(data.previousTo)}`
  const cancelRate = kpis.orders ? Math.round((kpis.cancelled / kpis.orders) * 100) : 0
  return (
    <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
      <StatTile
        label='Pedidos'
        value={kpis.orders}
        hint={versus(kpis.orders, previous.orders, range)}
      />
      <StatTile
        label='Vendido (entregados)'
        value={formatMoney(kpis.gmv)}
        hint={versus(kpis.gmv.amount, previous.gmv.amount, range)}
      />
      <StatTile
        label='Ticket promedio'
        value={kpis.delivered ? formatMoney(kpis.avgTicket) : '—'}
        hint={`${kpis.delivered} entregados`}
      />
      <StatTile
        label='Cancelados'
        value={kpis.cancelled}
        hint={kpis.orders ? `${cancelRate} % de los pedidos` : undefined}
      />
      <StatTile
        label='Clientes'
        value={kpis.customers}
        hint={versus(kpis.customers, previous.customers, range)}
      />
      <StatTile
        label='Clientes nuevos'
        value={kpis.newCustomers}
        hint={`${kpis.customers - kpis.newCustomers} volvieron a pedir`}
      />
      <StatTile
        label='Productos vendidos'
        value={formatMoney(kpis.sales)}
        hint='Sin envío ni propina'
      />
      <StatTile
        label='Entregados'
        value={kpis.delivered}
        hint={versus(kpis.delivered, previous.delivered, range)}
      />
    </div>
  )
}
