import { useDeferredValue, useState } from 'react'
import { PageHeader } from '@/components/shared/page-header'
import { PartnerStorePicker } from '@/components/shared/partner-store-picker'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { usePartnerStore } from '@/hooks/use-partner-store'
import { cn } from '@/lib/cn'
import { DashboardSkeleton } from '../components/partner-skeletons'
import { RangePicker } from '../components/range-picker'
import { SettlementView } from '../components/settlement-view'
import { lastDays, type DateRange } from '../model/partner'

export function PartnerSettlementPage() {
  const [range, setRange] = useState(() => lastDays(7))
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Portal Socios'
        title='Rendición'
        description='Lo que vendiste y lo que cobraron los repartidores, por día.'
        actions={
          <QueryBoundary fallback={null}>
            <PartnerStorePicker />
          </QueryBoundary>
        }
      />
      <RangePicker value={range} onChange={setRange} />
      <QueryBoundary fallback={<DashboardSkeleton />}>
        <Settlement range={range} />
      </QueryBoundary>
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
