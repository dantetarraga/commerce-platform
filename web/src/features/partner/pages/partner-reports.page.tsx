import { useDeferredValue, useState } from 'react'
import { PageHeader } from '@/components/shared/page-header'
import { RangePicker } from '@/components/shared/range-picker'
import { PartnerStorePicker } from '@/components/shared/partner-store-picker'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { usePartnerStore } from '@/hooks/use-partner-store'
import { cn } from '@/lib/cn'
import { DashboardSkeleton } from '../components/partner-skeletons'
import { SalesOverview } from '../components/sales-overview'
import { lastDays, type DateRange } from '@/lib/date-range'

export function PartnerReportsPage() {
  const [range, setRange] = useState(() => lastDays(7))
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Portal Socios'
        title='Reportes'
        description='Ventas, pedidos y lo más vendido, comparados con el periodo anterior.'
        actions={
          <QueryBoundary fallback={null}>
            <PartnerStorePicker />
          </QueryBoundary>
        }
      />
      <RangePicker value={range} onChange={setRange} />
      <QueryBoundary fallback={<DashboardSkeleton />}>
        <Report range={range} />
      </QueryBoundary>
    </div>
  )
}

function Report({ range }: { range: DateRange }) {
  const { store } = usePartnerStore()
  // Al cambiar el periodo se quedan las cifras anteriores hasta tener las nuevas.
  const deferred = useDeferredValue(range)
  if (!store) return null
  return (
    <div className={cn(deferred !== range && 'opacity-60 transition-opacity')}>
      <SalesOverview range={deferred} storeId={store.id} />
    </div>
  )
}
