import { useQuery } from '@tanstack/react-query'
import { useDeferredValue, useState } from 'react'
import { citiesQuery } from '@/app/api/lookups'
import { SelectField } from '@/components/shared/form-controls'
import { PageHeader } from '@/components/shared/page-header'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/cn'
import { dateTime } from '@/lib/datetime'
import { CommissionCard } from '../components/commission-card'
import { SettlementWeekReport } from '../components/settlement-week-report'
import type { SettlementFilters } from '../model/settlements'

function WeekSkeleton() {
  return (
    <div role='status' aria-label='Cargando liquidaciones' className='space-y-6'>
      <Skeleton className='h-10 w-72' />
      <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
        {[0, 1, 2, 3].map((index) => (
          <Skeleton key={index} className='h-20 w-full' />
        ))}
      </div>
      <Skeleton className='h-56 w-full' />
    </div>
  )
}

export function SettlementsPage() {
  const cities = useQuery(citiesQuery)
  const [filters, setFilters] = useState<SettlementFilters>(() => ({
    week: dateTime.toApiDate(),
    cityId: '',
  }))
  // Al cambiar de semana o ciudad se queda la anterior hasta tener la nueva.
  const deferred = useDeferredValue(filters)
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Liquidaciones'
        description='Cada semana, de lunes a domingo: lo vendido por cada negocio menos la comisión de Apamuy y lo que el negocio ya cobró.'
      />
      <QueryBoundary fallback={<Skeleton className='h-24 w-full' />}>
        <CommissionCard />
      </QueryBoundary>
      <div className='w-52'>
        <SelectField
          label='Ciudad'
          value={filters.cityId}
          onChange={(event) => setFilters({ ...filters, cityId: event.target.value })}
        >
          <option value=''>Todas las ciudades</option>
          {cities.data?.map((city) => (
            <option key={city.id} value={city.id}>
              {city.name}
            </option>
          ))}
        </SelectField>
      </div>
      <div className={cn(deferred !== filters && 'opacity-60 transition-opacity')}>
        <QueryBoundary fallback={<WeekSkeleton />}>
          <SettlementWeekReport
            filters={deferred}
            onWeekChange={(week) => setFilters({ ...filters, week })}
          />
        </QueryBoundary>
      </div>
    </div>
  )
}
