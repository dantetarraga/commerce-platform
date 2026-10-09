import { useQuery } from '@tanstack/react-query'
import { useDeferredValue, useState } from 'react'
import { citiesQuery } from '@/app/api/lookups'
import { SelectField } from '@/components/shared/form-controls'
import { PageHeader } from '@/components/shared/page-header'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { RangePicker } from '@/components/shared/range-picker'
import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/cn'
import { lastDays } from '@/lib/date-range'
import type { AnalyticsFilters } from '../actions/analytics.actions'
import { AnalyticsDashboard } from '../components/analytics-dashboard'

export function AdminHomePage() {
  const [filters, setFilters] = useState<AnalyticsFilters>(() => ({ ...lastDays(7), cityId: '' }))
  const cities = useQuery(citiesQuery)
  // Al cambiar el periodo o la ciudad se quedan las cifras anteriores hasta tener las nuevas.
  const deferred = useDeferredValue(filters)
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Inicio'
        description='Cómo va Apamuy: pedidos, ventas, tiempos y cancelaciones, comparados con el periodo anterior.'
        actions={
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
        }
      />
      <RangePicker value={filters} onChange={(range) => setFilters({ ...filters, ...range })} />
      <QueryBoundary fallback={<DashboardSkeleton />}>
        <div className={cn(deferred !== filters && 'opacity-60 transition-opacity')}>
          <AnalyticsDashboard filters={deferred} />
        </div>
      </QueryBoundary>
    </div>
  )
}

function DashboardSkeleton() {
  return (
    <div role='status' aria-label='Cargando cifras' className='space-y-6'>
      <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
        {Array.from({ length: 8 }, (_, index) => (
          <Skeleton key={index} className='h-20 w-full' />
        ))}
      </div>
      <Skeleton className='h-64 w-full' />
      <div className='grid gap-5 lg:grid-cols-2'>
        <Skeleton className='h-56 w-full' />
        <Skeleton className='h-56 w-full' />
      </div>
    </div>
  )
}
