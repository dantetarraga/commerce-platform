import { useSuspenseQuery } from '@tanstack/react-query'
import { Info } from 'lucide-react'
import { StatTile } from '@/components/shared/stat-tile'
import { dateTime } from '@/lib/datetime'
import { formatMoney } from '@/lib/money'
import type { DateRange } from '@/lib/date-range'
import { settlementQuery } from '../queries/partner.queries'

/** Lo vendido y lo cobrado por día de entrega. Suspende mientras carga. */
export function SettlementView({ range, storeId }: { range: DateRange; storeId: string }) {
  const { data: settlement } = useSuspenseQuery(settlementQuery(range, storeId))
  const days = settlement.days.filter((day) => day.delivered > 0).reverse()
  return (
    <div className='space-y-6'>
      <div role='note' className='bg-secondary/70 flex items-start gap-3 rounded-lg p-4 text-sm'>
        <Info className='text-primary mt-0.5 size-5 shrink-0' aria-hidden />
        <p>
          La comisión de Apamuy y las liquidaciones semanales todavía no están definidas. Mientras
          tanto ves lo que vendiste y lo que cobraron los repartidores; el envío y la propina son
          del repartidor.
        </p>
      </div>
      <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
        <StatTile
          label='Vendido'
          value={formatMoney(settlement.sales)}
          hint={`${settlement.delivered} entregas`}
        />
        <StatTile label='Efectivo cobrado' value={formatMoney(settlement.collected.CASH)} />
        <StatTile label='Yape' value={formatMoney(settlement.collected.YAPE)} />
        <StatTile label='Plin' value={formatMoney(settlement.collected.PLIN)} />
      </div>
      <section className='corner-exit-m bg-card border p-5'>
        <h2 className='mb-4 text-lg font-semibold'>Por día</h2>
        {days.length === 0 ? (
          <p className='text-muted-foreground text-sm'>Sin entregas en estas fechas.</p>
        ) : (
          <div className='overflow-x-auto'>
            <table className='w-full text-left text-sm'>
              <thead className='text-muted-foreground border-b text-xs'>
                <tr>
                  <th scope='col' className='py-2 pr-4'>
                    Día
                  </th>
                  <th scope='col' className='px-4 py-2 text-right'>
                    Entregas
                  </th>
                  <th scope='col' className='px-4 py-2 text-right'>
                    Vendido
                  </th>
                  <th scope='col' className='px-4 py-2 text-right'>
                    Efectivo
                  </th>
                  <th scope='col' className='px-4 py-2 text-right'>
                    Yape
                  </th>
                  <th scope='col' className='py-2 pl-4 text-right'>
                    Plin
                  </th>
                </tr>
              </thead>
              <tbody className='divide-y tabular-nums'>
                {days.map((day) => (
                  <tr key={day.date}>
                    <th scope='row' className='py-2 pr-4 font-semibold'>
                      {dateTime.formatApiDay(day.date)}
                    </th>
                    <td className='px-4 py-2 text-right'>{day.delivered}</td>
                    <td className='px-4 py-2 text-right'>{formatMoney(day.sales)}</td>
                    <td className='px-4 py-2 text-right'>{formatMoney(day.collected.CASH)}</td>
                    <td className='px-4 py-2 text-right'>{formatMoney(day.collected.YAPE)}</td>
                    <td className='py-2 pl-4 text-right'>{formatMoney(day.collected.PLIN)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  )
}
