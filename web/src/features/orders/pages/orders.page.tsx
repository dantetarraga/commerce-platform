import { useQuery } from '@tanstack/react-query'
import { useDeferredValue, useState } from 'react'
import { citiesQuery } from '@/app/api/lookups'
import { SelectField, TextField } from '@/components/shared/form-controls'
import { PageHeader } from '@/components/shared/page-header'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/cn'
import { LiveBoard } from '../components/live-board'
import { OrderDetailDialog } from '../components/order-detail-dialog'
import { OrdersHistory } from '../components/orders-history'
import { LiveBoardSkeleton, OrdersHistorySkeleton } from '../components/orders-skeletons'
import { ORDER_STATUS_LABEL, type AdminOrder, type OrderStatus } from '../model/orders'
import {
  useHistoryFilters,
  useOrdersCity,
  useOrdersTab,
  useOrdersViewActions,
  type OrdersTab,
} from '../stores/orders-view.store'

const TABS: { key: OrdersTab; label: string }[] = [
  { key: 'live', label: 'En vivo' },
  { key: 'history', label: 'Historial' },
]

export function OrdersPage() {
  const tab = useOrdersTab()
  const cityId = useOrdersCity()
  const { setTab, setCityId } = useOrdersViewActions()
  const cities = useQuery(citiesQuery)
  const [open, setOpen] = useState<AdminOrder | null>(null)
  // Al cambiar de ciudad se queda el tablero anterior hasta tener el nuevo.
  const deferredCity = useDeferredValue(cityId)
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Operación'
        title='Pedidos'
        description='Lo que pasa ahora en cada ciudad. Se actualiza solo.'
        actions={
          <div className='w-52'>
            <SelectField label='Ciudad' value={cityId} onChange={(e) => setCityId(e.target.value)}>
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
      <div role='tablist' aria-label='Vista de pedidos' className='flex gap-2 border-b'>
        {TABS.map((item) => (
          <button
            key={item.key}
            type='button'
            role='tab'
            aria-selected={tab === item.key}
            onClick={() => setTab(item.key)}
            className={cn(
              '-mb-px border-b-2 px-4 py-2 text-sm font-semibold transition-colors',
              tab === item.key
                ? 'border-primary text-primary'
                : 'text-muted-foreground hover:text-foreground border-transparent',
            )}
          >
            {item.label}
          </button>
        ))}
      </div>
      <div className={cn(deferredCity !== cityId && 'opacity-60 transition-opacity')}>
        {tab === 'live' ? (
          <QueryBoundary fallback={<LiveBoardSkeleton />}>
            <LiveBoard cityId={deferredCity} onOpen={setOpen} />
          </QueryBoundary>
        ) : (
          <HistoryPanel onOpen={setOpen} />
        )}
      </div>
      {open && <OrderDetailDialog order={open} onClose={() => setOpen(null)} />}
    </div>
  )
}

function HistoryPanel({ onOpen }: { onOpen: (order: AdminOrder) => void }) {
  const filters = useHistoryFilters()
  const { setDate, setStatus, setQuery } = useOrdersViewActions()
  const [search, setSearch] = useState(filters.q)
  const deferredFilters = useDeferredValue(filters)
  return (
    <section className='corner-exit-m bg-card space-y-6 border p-5 md:p-6'>
      <form
        className='grid gap-4 md:grid-cols-[auto_auto_minmax(0,1fr)_auto] md:items-end'
        onSubmit={(event) => {
          event.preventDefault()
          setQuery(search)
        }}
      >
        <TextField
          label='Día'
          type='date'
          value={filters.date}
          onChange={(event) => event.target.value && setDate(event.target.value)}
        />
        <SelectField
          label='Estado'
          value={filters.status}
          onChange={(event) => setStatus(event.target.value as OrderStatus | '')}
        >
          <option value=''>Todos</option>
          {Object.entries(ORDER_STATUS_LABEL).map(([status, label]) => (
            <option key={status} value={status}>
              {label}
            </option>
          ))}
        </SelectField>
        <TextField
          label='Código o celular del cliente'
          type='search'
          placeholder='#2481 o 987654321'
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <Button type='submit' variant='outline'>
          Buscar
        </Button>
      </form>
      <div className={cn(deferredFilters !== filters && 'opacity-60 transition-opacity')}>
        <QueryBoundary fallback={<OrdersHistorySkeleton />}>
          <OrdersHistory filters={deferredFilters} onOpen={onOpen} />
        </QueryBoundary>
      </div>
    </section>
  )
}
