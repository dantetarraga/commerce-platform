import { useQuery } from '@tanstack/react-query'
import { Link, useNavigate } from '@tanstack/react-router'
import { Store } from 'lucide-react'
import { useState } from 'react'
import { adminStoresQuery, citiesQuery } from '@/app/api/admin-lookups'
import { EmptyState } from '@/components/shared/empty-state'
import { SelectField, TextField } from '@/components/shared/form-controls'
import { PageHeader } from '@/components/shared/page-header'
import { ErrorState } from '@/components/shared/error-state'
import { ErrorNotice, LoadingState } from '@/components/shared/query-feedback'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { CategoryManager } from '../components/category-manager'
import { StoreFormDialog } from '../components/store-form'

export function CatalogPage() {
  const stores = useQuery(adminStoresQuery)
  const cities = useQuery(citiesQuery)
  const [search, setSearch] = useState('')
  const [cityId, setCityId] = useState('')
  const [status, setStatus] = useState('all')
  const [creating, setCreating] = useState(false)
  const navigate = useNavigate()
  const normalizedSearch = search.trim().toLocaleLowerCase('es-PE')
  const filtered =
    stores.data?.filter(
      (store) =>
        (!cityId || store.cityId === cityId) &&
        (status === 'all' || store.isActive === (status === 'published')) &&
        store.name.toLocaleLowerCase('es-PE').includes(normalizedSearch),
    ) ?? []
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Catálogo'
        description='Negocios y cartas que tus clientes encuentran en Apamuy.'
        actions={<Button onClick={() => setCreating(true)}>Nuevo negocio</Button>}
      />
      <section className='corner-exit-m bg-card space-y-6 border p-5 md:p-6'>
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
            {cities.data?.map((city) => (
              <option key={city.id} value={city.id}>
                {city.name}
              </option>
            ))}
          </SelectField>
          <SelectField
            label='Publicación'
            value={status}
            onChange={(event) => setStatus(event.target.value)}
          >
            <option value='all'>Todos</option>
            <option value='published'>Publicados</option>
            <option value='draft'>Borradores</option>
          </SelectField>
        </div>
        <ErrorNotice
          error={cities.error}
          isRetrying={cities.isFetching}
          onRetry={() => {
            void cities.refetch()
          }}
        />
        {stores.isPending ? (
          <LoadingState label='Cargando negocios…' />
        ) : stores.isError ? (
          <ErrorState
            error={stores.error}
            isRetrying={stores.isFetching}
            onRetry={() => {
              void stores.refetch()
            }}
          />
        ) : filtered.length === 0 ? (
          <EmptyState
            icon={Store}
            title={stores.data.length ? 'Sin coincidencias' : 'Tu primer negocio empieza aquí'}
            description={
              stores.data.length
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
                    {cities.data?.find((city) => city.id === store.cityId)?.name ??
                      'Ciudad no disponible'}{' '}
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
                          {cities.data?.find((city) => city.id === store.cityId)?.name ??
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
      </section>
      <CategoryManager />
      {creating && (
        <StoreFormDialog
          onClose={() => setCreating(false)}
          onSaved={(storeId) => {
            setCreating(false)
            void navigate({ to: '/admin/catalog/$storeId', params: { storeId } })
          }}
        />
      )}
    </div>
  )
}
