import { useQuery } from '@tanstack/react-query'
import { useDeferredValue, useState } from 'react'
import { citiesQuery } from '@/app/api/lookups'
import { SelectField, TextField } from '@/components/shared/form-controls'
import { PageHeader } from '@/components/shared/page-header'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/cn'
import { dateTime } from '@/lib/datetime'
import { CashReport } from '../components/cash-report'
import type { CashFilters } from '../model/cash'

function CashSkeleton() {
  return (
    <div role='status' aria-label='Cargando caja' className='space-y-6'>
      <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
        {[0, 1, 2, 3].map((index) => (
          <Skeleton key={index} className='h-20 w-full' />
        ))}
      </div>
      <Skeleton className='h-56 w-full' />
    </div>
  )
}

export function CashPage() {
  const cities = useQuery(citiesQuery)
  const [filters, setFilters] = useState<CashFilters>(() => ({
    date: dateTime.toApiDate(),
    cityId: '',
  }))
  // Al cambiar de día o ciudad se queda la caja anterior hasta tener la nueva.
  const deferred = useDeferredValue(filters)
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Caja'
        description='Lo que cobró cada repartidor contraentrega y lo que vendió cada negocio.'
      />
      <div className='flex flex-wrap items-end gap-3'>
        <div className='w-44'>
          <TextField
            label='Día'
            type='date'
            value={filters.date}
            max={dateTime.toApiDate()}
            onChange={(event) =>
              event.target.value && setFilters({ ...filters, date: event.target.value })
            }
          />
        </div>
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
      </div>
      <div className={cn(deferred !== filters && 'opacity-60 transition-opacity')}>
        <QueryBoundary fallback={<CashSkeleton />}>
          <CashReport filters={deferred} />
        </QueryBoundary>
      </div>
    </div>
  )
}
