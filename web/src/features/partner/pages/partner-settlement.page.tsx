import { useDeferredValue, useState } from 'react'
import { PageHeader } from '@/components/shared/page-header'
import { RangePicker } from '@/components/shared/range-picker'
import { PartnerStorePicker } from '@/components/shared/partner-store-picker'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { usePartnerStore } from '@/hooks/use-partner-store'
import { cn } from '@/lib/cn'
import { dateTime } from '@/lib/datetime'
import { DashboardSkeleton } from '../components/partner-skeletons'
import { SettlementView } from '../components/settlement-view'
import { WeeklySettlementView } from '../components/weekly-settlement-view'
import { lastDays, type DateRange } from '@/lib/date-range'

export function PartnerSettlementPage() {
  const [range, setRange] = useState(() => lastDays(7))
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Portal Socios'
        title='Rendición'
        description='Tu liquidación de cada semana y lo que cobraron los repartidores, por día.'
        actions={
          <QueryBoundary fallback={null}>
            <PartnerStorePicker />
          </QueryBoundary>
        }
      />
      <section className='corner-exit-m bg-card space-y-4 border p-5'>
        <div>
          <h2 className='text-lg font-semibold'>Liquidación semanal</h2>
          <p className='text-muted-foreground text-sm'>
            De lunes a domingo: lo vendido menos la comisión de Apamuy y lo que cobraste tú. Apamuy
            la liquida desde el lunes siguiente.
          </p>
        </div>
        <QueryBoundary fallback={<DashboardSkeleton />}>
          <WeeklySettlement />
        </QueryBoundary>
      </section>
      <section className='space-y-4'>
        <h2 className='text-lg font-semibold'>Por día</h2>
        <RangePicker value={range} onChange={setRange} />
        <QueryBoundary fallback={<DashboardSkeleton />}>
          <Settlement range={range} />
        </QueryBoundary>
      </section>
    </div>
  )
}

function WeeklySettlement() {
  const { store } = usePartnerStore()
  const [week, setWeek] = useState(() => dateTime.toApiDate())
  const deferred = useDeferredValue(week)
  if (!store) return null
  return (
    <div className={cn(deferred !== week && 'opacity-60 transition-opacity')}>
      <WeeklySettlementView week={deferred} storeId={store.id} onWeekChange={setWeek} />
    </div>
  )
}

function Settlement({ range }: { range: DateRange }) {
  const { store } = usePartnerStore()
  const deferred = useDeferredValue(range)
  if (!store) return null
  return (
    <div className={cn(deferred !== range && 'opacity-60 transition-opacity')}>
      <SettlementView range={deferred} storeId={store.id} />
    </div>
  )
}
