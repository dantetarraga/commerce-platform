import { useSuspenseQuery } from '@tanstack/react-query'
import type { ReactNode } from 'react'
import { BarChart } from '@/components/shared/bar-chart'
import { StatTile } from '@/components/shared/stat-tile'
import { dateTime } from '@/lib/datetime'
import { formatMoney } from '@/lib/money'
import { changeLabel, hourLabel, type DateRange } from '@/lib/date-range'
import type { SalesSummary } from '../model/partner'
import { salesReportQuery } from '../queries/partner.queries'
import { PaymentsBreakdown } from './payments-breakdown'
import { TopProducts } from './top-products'

function Card({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className='corner-exit-m bg-card space-y-4 border p-5'>
      <h2 className='text-lg font-semibold'>{title}</h2>
      {children}
    </section>
  )
}

const ordersLabel = (count: number) => `${count} ${count === 1 ? 'pedido' : 'pedidos'}`

/** Gráfico de ventas por hora, compartido con el inicio. */
export function HourlySales({ summary }: { summary: SalesSummary }) {
  if (summary.salesByHour.length === 0) {
    return <p className='text-muted-foreground text-sm'>Aún no hay ventas entregadas.</p>
  }
  return (
    <BarChart
      title='Ventas por hora'
      data={summary.salesByHour.map((slot) => ({
        key: String(slot.hour),
        label: hourLabel(slot.hour),
        value: slot.sales.amount,
        display: formatMoney(slot.sales),
        detail: ordersLabel(slot.orders),
      }))}
    />
  )
}

/** Ventas de un rango comparadas con el periodo anterior. Suspende mientras carga. */
export function SalesOverview({ range, storeId }: { range: DateRange; storeId: string }) {
  const { data: report } = useSuspenseQuery(salesReportQuery(range, storeId))
  const previous = `vs. ${dateTime.formatApiDay(report.previous.from)} – ${dateTime.formatApiDay(report.previous.to)}`
  const salesChange = changeLabel(report.sales.amount, report.previous.sales.amount)
  const ordersChange = changeLabel(report.deliveredCount, report.previous.deliveredCount)
  return (
    <div className='space-y-6'>
      <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
        <StatTile
          label='Ventas'
          value={formatMoney(report.sales)}
          hint={salesChange ? `${salesChange} ${previous}` : 'Sin ventas en el periodo anterior'}
        />
        <StatTile
          label='Pedidos entregados'
          value={report.deliveredCount}
          hint={ordersChange ? `${ordersChange} ${previous}` : undefined}
        />
        <StatTile
          label='Ticket promedio'
          value={report.averageTicket ? formatMoney(report.averageTicket) : '—'}
        />
        <StatTile
          label='Cancelados'
          value={report.cancelledCount}
          hint={
            report.averagePrepMinutes !== null
              ? `Preparación promedio: ${report.averagePrepMinutes} min`
              : undefined
          }
        />
      </div>
      <Card title='Ventas por día'>
        {report.sales.amount === 0 ? (
          <p className='text-muted-foreground text-sm'>Sin ventas entregadas en estas fechas.</p>
        ) : (
          <BarChart
            title='Ventas por día'
            data={report.salesByDay.map((day) => ({
              key: day.date,
              label: dateTime.formatApiDay(day.date),
              value: day.sales.amount,
              display: formatMoney(day.sales),
              detail: `${ordersLabel(day.delivered)}${day.cancelled ? ` · ${day.cancelled} cancelados` : ''}`,
            }))}
          />
        )}
      </Card>
      <div className='grid gap-5 lg:grid-cols-2'>
        <Card title='Más vendidos'>
          <TopProducts products={report.topProducts} />
        </Card>
        <Card title='Cómo pagaron'>
          <PaymentsBreakdown payments={report.payments} />
        </Card>
      </div>
      <Card
        title={
          report.peakHour === null
            ? 'Ventas por hora'
            : `Ventas por hora · más pedidos a las ${hourLabel(report.peakHour)}`
        }
      >
        <HourlySales summary={report} />
      </Card>
    </div>
  )
}
