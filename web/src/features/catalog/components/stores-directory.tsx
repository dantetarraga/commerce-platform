import { useSuspenseQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { Store } from 'lucide-react'
import { adminStoresQuery, citiesQuery } from '@/app/api/lookups'
import { EmptyState } from '@/components/shared/empty-state'
import { SelectField, TextField } from '@/components/shared/form-controls'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import {
  useCatalogFilters,
  useCatalogFiltersActions,
  type PublicationFilter,
} from '../stores/catalog-filters.store'

/** Negocios con sus filtros. Suspende mientras cargan negocios y ciudades. */
export function StoresDirectory() {
  const { data: stores } = useSuspenseQuery(adminStoresQuery)
  const { data: cities } = useSuspenseQuery(citiesQuery)
  const { search, cityId, status } = useCatalogFilters()
  const { setSearch, setCityId, setStatus } = useCatalogFiltersActions()
  const normalizedSearch = search.trim().toLocaleLowerCase('es-PE')
  const filtered = stores.filter(
    (store) =>
      (!cityId || store.cityId === cityId) &&
      (status === 'all' || store.isActive === (status === 'published')) &&
      store.name.toLocaleLowerCase('es-PE').includes(normalizedSearch),
  )
  return (
    <div className='space-y-6'>
      <div className='grid gap-4 md:grid-cols-3'>
        <TextField
          label='Buscar negocio'
          type='search'
          placeholder='Nombre del negocio'
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <SelectField
          label='Ciudad'
          value={cityId}
          onChange={(event) => setCityId(event.target.value)}
        >
          <option value=''>Todas las ciudades</option>
          {cities.map((city) => (
            <option key={city.id} value={city.id}>
              {city.name}
            </option>
          ))}
        </SelectField>
        <SelectField
          label='Publicación'
          value={status}
          onChange={(event) => setStatus(event.target.value as PublicationFilter)}
        >
          <option value='all'>Todos</option>
          <option value='published'>Publicados</option>
          <option value='draft'>Borradores</option>
        </SelectField>
      </div>
      {filtered.length === 0 ? (
        <EmptyState
          icon={Store}
          title={stores.length ? 'Sin coincidencias' : 'Tu primer negocio empieza aquí'}
          description={
            stores.length
              ? 'Prueba con otro nombre o cambia los filtros.'
              : 'Registra al dueño en Socios y crea su negocio como borrador.'
          }
        />
      ) : (
        <div>
          <ul className='divide-y md:hidden'>
            {filtered.map((store) => (
              <li key={store.id} className='space-y-3 py-4'>
                <Link
                  to='/admin/catalog/$storeId'
                  params={{ storeId: store.id }}
                  className='text-primary block font-semibold'
                >
                  {store.name}
                </Link>
                <p className='text-muted-foreground text-sm'>
                  {cities.find((city) => city.id === store.cityId)?.name ?? 'Ciudad no disponible'}{' '}
                  · {store.productCount} productos
                </p>
                <div className='flex flex-wrap gap-2'>
                  <StatusBadge active={store.isActive}>
                    {store.isActive ? 'Publicado' : 'Borrador'}
                  </StatusBadge>
                  {!store.isAcceptingOrders && <StatusBadge>Pedidos en pausa</StatusBadge>}
                </div>
                <Button asChild variant='outline' size='sm'>
                  <Link
                    to='/admin/catalog/$storeId'
                    params={{ storeId: store.id }}
                    aria-label={`Gestionar ${store.name}`}
                  >
                    Gestionar negocio
                  </Link>
                </Button>
              </li>
            ))}
          </ul>
          <div className='hidden overflow-x-auto md:block'>
            <table className='w-full text-left text-sm'>
              <caption className='text-muted-foreground pb-3 text-left'>
                {filtered.length} negocios
              </caption>
              <thead className='text-muted-foreground border-b text-xs'>
                <tr>
                  <th scope='col' className='py-3 pr-4'>
                    Negocio
                  </th>
                  <th scope='col' className='px-4 py-3'>
                    Estado
                  </th>
                  <th scope='col' className='px-4 py-3'>
                    Productos
                  </th>
                  <th scope='col' className='py-3 pl-4'>
                    <span className='sr-only'>Acciones</span>
                  </th>
                </tr>
              </thead>
              <tbody className='divide-y'>
                {filtered.map((store) => (
                  <tr key={store.id}>
                    <td className='py-4 pr-4'>
                      <Link
                        to='/admin/catalog/$storeId'
                        params={{ storeId: store.id }}
                        className='hover:text-primary font-semibold'
                      >
                        {store.name}
                      </Link>
                      <p className='text-muted-foreground mt-1 text-xs'>
                        {cities.find((city) => city.id === store.cityId)?.name ??
                          'Ciudad no disponible'}
                      </p>
                    </td>
                    <td className='px-4 py-4'>
                      <div className='flex flex-wrap gap-2'>
                        <StatusBadge active={store.isActive}>
                          {store.isActive ? 'Publicado' : 'Borrador'}
                        </StatusBadge>
                        {!store.isAcceptingOrders && <StatusBadge>Pedidos en pausa</StatusBadge>}
                      </div>
                    </td>
                    <td className='px-4 py-4 tabular-nums'>{store.productCount}</td>
                    <td className='py-4 pl-4'>
                      <Button asChild variant='outline' size='sm'>
                        <Link
                          to='/admin/catalog/$storeId'
                          params={{ storeId: store.id }}
                          aria-label={`Gestionar ${store.name}`}
                        >
                          Gestionar
                        </Link>
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}
