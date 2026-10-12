import { APIProvider, AdvancedMarker, InfoWindow, Map, Pin } from '@vis.gl/react-google-maps'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { Bike, MapPinOff } from 'lucide-react'
import { useState } from 'react'
import { queryKeys } from '@/app/api'
import type { CityOption } from '@/app/api/lookups'
import { env } from '@/app/config/env'
import { ErrorState } from '@/components/shared/error-state'
import { Skeleton } from '@/components/ui/skeleton'
import { useRealtimeEvent } from '@/hooks/use-realtime-event'
import { cn } from '@/lib/cn'
import { dateTime } from '@/lib/datetime'
import {
  COURIER_STATUS_LABEL,
  ORDER_STATUS_LABEL,
  type CourierOnMap,
  type CouriersMap as CouriersMapData,
} from '../model/orders'
import { couriersMapQuery } from '../queries/orders.queries'

interface CourierMoved {
  courierId: string
  cityId: string
  lat: number
  lng: number
  at: string
}

// Los marcadores pintan en el DOM: las variables de color del tema sirven tal cual.
const PIN_COLOR = {
  busy: 'var(--primary)',
  free: 'var(--success)',
  stale: 'var(--muted-foreground)',
} as const

/** Espinar, si no hay ciudad elegida ni repartidores con ubicación. */
const FALLBACK_CENTER = { lat: -14.7936, lng: -71.4128 }

/**
 * Dónde está cada repartidor conectado y qué pedido lleva. La ubicación llega por
 * WebSocket; la lista de al lado dice lo mismo en texto (y sirve sin la key de Maps).
 */
export function CouriersMap({ cityId, cities }: { cityId: string; cities: CityOption[] }) {
  const query = useQuery(couriersMapQuery(cityId))
  const queryClient = useQueryClient()
  const [openId, setOpenId] = useState<string | null>(null)

  useRealtimeEvent<CourierMoved>('admin.courier.moved', (event) => {
    if (cityId && event.cityId !== cityId) return
    queryClient.setQueryData<CouriersMapData>(queryKeys.orders.couriers(cityId), (current) =>
      current
        ? {
            ...current,
            items: current.items.map((courier) =>
              courier.id === event.courierId
                ? {
                    ...courier,
                    location: { lat: event.lat, lng: event.lng, at: event.at, stale: false },
                  }
                : courier,
            ),
          }
        : current,
    )
  })

  const couriers = query.data?.items ?? []
  const located = couriers.filter((c) => c.location)
  const city = cities.find((c) => c.id === cityId)
  const center = city
    ? { lat: city.centerLat, lng: city.centerLng }
    : located[0]?.location
      ? { lat: located[0].location.lat, lng: located[0].location.lng }
      : FALLBACK_CENTER

  return (
    <section
      aria-labelledby='couriers-map-title'
      className='corner-exit-m bg-card space-y-4 border p-5 md:p-6'
    >
      <header className='flex flex-wrap items-baseline justify-between gap-2'>
        <div>
          <h2 id='couriers-map-title' className='font-semibold'>
            Repartidores
          </h2>
          <p className='text-muted-foreground text-sm'>
            Los conectados ahora. La posición se actualiza sola mientras la app comparte su
            ubicación.
          </p>
        </div>
        <span className='font-display text-xl font-semibold tabular-nums'>{couriers.length}</span>
      </header>
      {query.isPending ? (
        <Skeleton className='h-72 w-full rounded-lg' />
      ) : query.isError ? (
        <ErrorState
          error={query.error}
          onRetry={() => {
            query.refetch().catch(() => undefined)
          }}
        />
      ) : (
        <div className='grid gap-4 lg:grid-cols-[minmax(0,1fr)_20rem]'>
          {env.googleMapsApiKey ? (
            <div className='h-80 overflow-hidden rounded-lg border lg:h-[26rem]'>
              <APIProvider apiKey={env.googleMapsApiKey} language='es' region='PE'>
                <Map
                  key={cityId || 'all'}
                  mapId={env.googleMapsMapId}
                  defaultCenter={center}
                  defaultZoom={city ? 14 : 13}
                  gestureHandling='cooperative'
                  disableDefaultUI
                  zoomControl
                >
                  {located.map((courier) => (
                    <CourierMarker
                      key={courier.id}
                      courier={courier}
                      open={openId === courier.id}
                      onToggle={() => setOpenId(openId === courier.id ? null : courier.id)}
                    />
                  ))}
                </Map>
              </APIProvider>
            </div>
          ) : (
            <div className='bg-secondary/50 text-muted-foreground flex items-center justify-center rounded-lg p-6 text-center text-sm'>
              Para ver el mapa, configura VITE_GOOGLE_MAPS_API_KEY. Mientras, la lista muestra dónde
              está cada repartidor.
            </div>
          )}
          <CouriersList couriers={couriers} />
        </div>
      )}
    </section>
  )
}

function CourierMarker({
  courier,
  open,
  onToggle,
}: {
  courier: CourierOnMap
  open: boolean
  onToggle: () => void
}) {
  const location = courier.location!
  // Ocupado en terracota, libre en verde y sin señal en gris; la lista lo dice en texto.
  const tone = location.stale ? 'stale' : courier.order ? 'busy' : 'free'
  return (
    <>
      <AdvancedMarker
        position={{ lat: location.lat, lng: location.lng }}
        title={`${courier.name}: ${courierState(courier)}`}
        onClick={onToggle}
      >
        <Pin
          background={PIN_COLOR[tone]}
          borderColor='var(--foreground)'
          glyphColor='var(--background)'
        />
      </AdvancedMarker>
      {open && (
        <InfoWindow
          position={{ lat: location.lat, lng: location.lng }}
          onCloseClick={onToggle}
          headerDisabled
        >
          <div className='text-ink space-y-1 text-sm'>
            <p className='font-semibold'>{courier.name}</p>
            <p>{courier.vehicleLabel}</p>
            <p>{courierState(courier)}</p>
          </div>
        </InfoWindow>
      )}
    </>
  )
}

function courierState(courier: CourierOnMap) {
  if (courier.order) {
    return `#${courier.order.code} de ${courier.order.storeName}: ${ORDER_STATUS_LABEL[courier.order.status].toLowerCase()}`
  }
  return COURIER_STATUS_LABEL[courier.status]
}

function CouriersList({ couriers }: { couriers: CourierOnMap[] }) {
  if (couriers.length === 0) {
    return (
      <p className='text-muted-foreground rounded-lg border p-6 text-center text-sm'>
        No hay repartidores conectados en esta ciudad.
      </p>
    )
  }
  return (
    <ul
      className='max-h-[26rem] divide-y overflow-y-auto rounded-lg border'
      aria-label='Repartidores conectados'
    >
      {couriers.map((courier) => {
        const location = courier.location
        return (
          <li key={courier.id} className='flex gap-3 p-3'>
            {location ? (
              <Bike
                aria-hidden
                className={cn(
                  'mt-0.5 size-5 shrink-0',
                  location.stale ? 'text-muted-foreground' : 'text-primary',
                )}
              />
            ) : (
              <MapPinOff aria-hidden className='text-muted-foreground mt-0.5 size-5 shrink-0' />
            )}
            <div className='min-w-0 flex-1 space-y-0.5 text-sm'>
              <p className='font-semibold'>
                {courier.name}{' '}
                <span className='text-muted-foreground font-normal'>· {courier.vehicleLabel}</span>
              </p>
              <p>{courierState(courier)}</p>
              <p
                className={cn(
                  'text-xs',
                  location?.stale ? 'text-destructive' : 'text-muted-foreground',
                )}
              >
                {location
                  ? `${location.stale ? 'Sin señal desde' : 'Ubicación de'} ${dateTime.formatRelative(location.at)}`
                  : 'Aún no comparte su ubicación'}
                {location && (
                  <>
                    {' · '}
                    <a
                      className='underline underline-offset-2'
                      href={`https://www.google.com/maps?q=${location.lat},${location.lng}`}
                      target='_blank'
                      rel='noreferrer'
                    >
                      Abrir en Google Maps
                    </a>
                  </>
                )}
              </p>
            </div>
          </li>
        )
      })}
    </ul>
  )
}
