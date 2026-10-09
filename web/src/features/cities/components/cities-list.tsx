import { useSuspenseQuery } from '@tanstack/react-query'
import { MapPinned } from 'lucide-react'
import { useState } from 'react'
import { ConfirmActionDialog, type ConfirmAction } from '@/components/shared/confirm-action-dialog'
import { EmptyState } from '@/components/shared/empty-state'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { formatMoney } from '@/lib/money'
import type { AdminCity } from '../model/city'
import { toggleCityMutation } from '../mutations/cities.mutations'
import { adminCitiesQuery } from '../queries/cities.queries'

function Fact({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className='text-muted-foreground text-xs'>{label}</dt>
      <dd className='font-semibold tabular-nums'>{value}</dd>
    </div>
  )
}

/** Ciudades con sus parámetros y lo que cobra la tarifa. Suspende mientras cargan. */
export function CitiesList({ onEdit }: { onEdit: (city: AdminCity) => void }) {
  const { data: cities } = useSuspenseQuery(adminCitiesQuery)
  const [action, setAction] = useState<ConfirmAction | null>(null)
  if (cities.length === 0) {
    return (
      <EmptyState
        icon={MapPinned}
        title='Sin ciudades'
        description='Crea la primera para empezar a repartir.'
      />
    )
  }
  return (
    <>
      <ul className='space-y-5'>
        {cities.map((city) => (
          <li key={city.id} className='corner-exit-m bg-card space-y-5 border p-5 md:p-6'>
            <div className='flex flex-wrap items-start justify-between gap-4'>
              <div className='space-y-1'>
                <h2 className='text-xl font-semibold'>{city.name}</h2>
                <p className='text-muted-foreground text-sm'>
                  {[city.region, `${city.storeCount} negocios`, `${city.courierCount} repartidores`]
                    .filter(Boolean)
                    .join(' · ')}
                </p>
              </div>
              <div className='flex flex-wrap items-center gap-2'>
                <StatusBadge active={city.isActive}>
                  {city.isActive ? 'Recibe pedidos' : 'Inactiva'}
                </StatusBadge>
                <Button variant='outline' size='sm' onClick={() => onEdit(city)}>
                  Editar
                </Button>
                <Button
                  variant='ghost'
                  size='sm'
                  onClick={() =>
                    setAction({
                      title: city.isActive ? `Pausar ${city.name}` : `Activar ${city.name}`,
                      description: city.isActive
                        ? 'Los clientes de esta ciudad no podrán hacer pedidos nuevos. Solo se puede si no hay pedidos en curso.'
                        : 'Los clientes podrán pedir a los negocios publicados de esta ciudad.',
                      label: city.isActive ? 'Pausar ciudad' : 'Activar ciudad',
                      success: city.isActive ? 'Ciudad pausada.' : 'Ciudad activada.',
                      destructive: city.isActive,
                      mutation: toggleCityMutation(city.id, city.isActive),
                    })
                  }
                >
                  {city.isActive ? 'Pausar' : 'Activar'}
                </Button>
              </div>
            </div>
            <dl className='grid grid-cols-2 gap-4 text-sm sm:grid-cols-3 lg:grid-cols-6'>
              <Fact label='Zona de reparto' value={`${city.coverageKm} km`} />
              <Fact label='Máximo por calle' value={`${city.maxDeliveryKm} km`} />
              <Fact label='Tarifa base' value={formatMoney(city.baseDeliveryFee)} />
              <Fact label='Por km' value={formatMoney(city.feePerKm)} />
              <Fact label='Factor de ruta' value={`× ${city.routeFactor}`} />
              <Fact label='Velocidad' value={`${city.avgSpeedKmh} km/h`} />
            </dl>
            <div className='bg-secondary/60 space-y-2 rounded-lg p-4'>
              <p className='text-sm font-semibold'>Así cobra hoy</p>
              <ul className='grid gap-2 text-sm sm:grid-cols-3'>
                {city.feeExamples.map((example) => (
                  <li key={example.straightKm}>
                    <span className='font-semibold tabular-nums'>{formatMoney(example.fee)}</span>{' '}
                    <span className='text-muted-foreground'>
                      a {example.straightKm} km en el mapa ({example.streetKm} km por calle, ~
                      {example.travelMinutes} min)
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          </li>
        ))}
      </ul>
      {action && <ConfirmActionDialog action={action} onClose={() => setAction(null)} />}
    </>
  )
}
