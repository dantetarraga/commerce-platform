import { useSuspenseQuery } from '@tanstack/react-query'
import { StatTile } from '@/components/shared/stat-tile'
import { dateTime } from '@/lib/datetime'
import { formatMoney } from '@/lib/money'
import { hourLabel } from '../model/partner'
import { daySummaryQuery } from '../queries/partner.queries'
import { HourlySales } from './sales-overview'
import { TopProducts } from './top-products'

/** Cómo va el día en todos sus negocios. Se actualiza cada minuto. Suspende mientras carga. */
export function TodaySummary() {
  const { data: today } = useSuspenseQuery(daySummaryQuery(dateTime.toApiDate()))
  return (
    <div className='space-y-6'>
      <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
        <StatTile label='Vendido hoy' value={formatMoney(today.sales)} />
        <StatTile label='Entregados' value={today.deliveredCount} />
        <StatTile label='En curso' value={today.activeCount} />
        <StatTile
          label='Preparación promedio'
          value={today.averagePrepMinutes === null ? '—' : `${today.averagePrepMinutes} min`}
          hint={today.peakHour === null ? undefined : `Hora pico: ${hourLabel(today.peakHour)}`}
        />
      </div>
      <div className='grid gap-5 lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]'>
        <section className='corner-exit-m bg-card space-y-4 border p-5'>
          <h2 className='text-lg font-semibold'>Ventas por hora</h2>
          <HourlySales summary={today} />
        </section>
        <section className='corner-exit-m bg-card space-y-4 border p-5'>
          <h2 className='text-lg font-semibold'>Lo más pedido hoy</h2>
          <TopProducts products={today.topProducts} />
        </section>
      </div>
    </div>
  )
}
