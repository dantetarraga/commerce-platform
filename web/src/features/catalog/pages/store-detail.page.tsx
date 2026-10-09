import { useQuery } from '@tanstack/react-query'
import { Link, useNavigate, useParams } from '@tanstack/react-router'
import { ArrowLeft, UtensilsCrossed } from 'lucide-react'
import { useState } from 'react'
import { http } from '@/app/api'
import { EmptyState } from '@/components/shared/empty-state'
import { SelectField, TextField } from '@/components/shared/form-controls'
import { PageHeader } from '@/components/shared/page-header'
import { ErrorState } from '@/components/shared/error-state'
import { LoadingState } from '@/components/shared/query-feedback'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { formatMoney } from '@/lib/money'
import { storeQuery } from '../api/catalog.api'
import { CatalogActionDialog, type CatalogAction } from '../components/catalog-action'
import { ProductFormDialog } from '../components/product-form'
import { ScheduleFormDialog } from '../components/schedule-form'
import { SectionFormDialog } from '../components/section-form'
import { StoreFormDialog } from '../components/store-form'
import { minutesToTime, WEEK_DAYS, type MenuSection, type Product } from '../model/catalog'

type Editor =
  | { kind: 'store' }
  | { kind: 'schedule' }
  | { kind: 'product'; product?: Product }
  | { kind: 'section'; section?: MenuSection }

export function StoreDetailPage() {
  const { storeId } = useParams({ from: '/admin/catalog/$storeId' })
  const query = useQuery(storeQuery(storeId))
  const navigate = useNavigate()
  const [editor, setEditor] = useState<Editor | null>(null)
  const [action, setAction] = useState<CatalogAction | null>(null)
  const [search, setSearch] = useState('')
  const [sectionId, setSectionId] = useState('all')
  if (query.isPending) return <LoadingState label='Cargando negocio…' />
  if (query.isError) {
    return (
      <ErrorState
        error={query.error}
        isRetrying={query.isFetching}
        onRetry={() => {
          void query.refetch()
        }}
      />
    )
  }
  const store = query.data
  const products = store.products.filter(
    (product) =>
      product.name.toLocaleLowerCase('es-PE').includes(search.trim().toLocaleLowerCase('es-PE')) &&
      (sectionId === 'all' || (product.menuSectionId ?? '') === sectionId),
  )
  const handleClose = () => setEditor(null)
  function handlePublication() {
    setAction({
      title: store.isActive ? 'Pasar negocio a borrador' : 'Publicar negocio',
      description: store.isActive
        ? `${store.name} dejará de aparecer en la app del cliente. Sus pedidos actuales se conservan.`
        : `${store.name} aparecerá en la app. Revisa sus horarios, ubicación y productos antes de publicar.`,
      label: store.isActive ? 'Pasar a borrador' : 'Publicar',
      success: 'Publicación actualizada.',
      run: () => http.patch(`/admin/stores/${store.id}`, { isActive: !store.isActive }),
    })
  }
  return (
    <div className='space-y-8'>
      <Link
        to='/admin/catalog'
        className='text-muted-foreground hover:text-primary inline-flex items-center gap-2 text-sm'
      >
        <ArrowLeft className='size-4' aria-hidden />
        Volver al catálogo
      </Link>
      <PageHeader
        eyebrow='Catálogo'
        title={store.name}
        description={store.addressLine}
        actions={
          <>
            <Button variant='outline' onClick={() => setEditor({ kind: 'store' })}>
              Editar negocio
            </Button>
            <Button onClick={handlePublication}>
              {store.isActive ? 'Pasar a borrador' : 'Publicar negocio'}
            </Button>
          </>
        }
      />
      <div className='flex flex-wrap gap-3'>
        <StatusBadge active={store.isActive}>
          {store.isActive ? 'Publicado' : 'Borrador'}
        </StatusBadge>
        <StatusBadge active={store.isAcceptingOrders}>
          {store.isAcceptingOrders ? 'Recibe pedidos según horario' : 'Pedidos en pausa'}
        </StatusBadge>
      </div>
      <div className='grid gap-5 lg:grid-cols-2'>
        <section className='corner-exit-m bg-card space-y-4 border p-5'>
          <div className='flex items-center justify-between gap-3'>
            <h2 className='text-xl font-semibold'>Horarios</h2>
            <Button variant='outline' size='sm' onClick={() => setEditor({ kind: 'schedule' })}>
              Editar horarios
            </Button>
          </div>
          {store.schedules.length ? (
            <ul className='space-y-2 text-sm'>
              {store.schedules.map((schedule, index) => (
                <li key={index} className='flex flex-wrap justify-between gap-2'>
                  <span>{WEEK_DAYS[schedule.dayOfWeek]}</span>
                  <span className='text-muted-foreground tabular-nums'>
                    {minutesToTime(schedule.opensAt)} – {minutesToTime(schedule.closesAt)}
                    {schedule.closesAt < schedule.opensAt ? ' (+1 día)' : ''}
                  </span>
                </li>
              ))}
            </ul>
          ) : (
            <p className='text-muted-foreground text-sm'>
              Sin turnos. Añade horarios para que el negocio aparezca abierto.
            </p>
          )}
        </section>
        <section className='corner-exit-m bg-card space-y-4 border p-5'>
          <div className='flex items-center justify-between gap-3'>
            <h2 className='text-xl font-semibold'>Secciones de la carta</h2>
            <Button variant='outline' size='sm' onClick={() => setEditor({ kind: 'section' })}>
              Nueva sección
            </Button>
          </div>
          {store.sections.length ? (
            <ul className='space-y-2'>
              {store.sections.map((section) => (
                <li
                  key={section.id}
                  className='flex flex-wrap items-center justify-between gap-2 text-sm'
                >
                  <span>{section.name}</span>
                  <div className='flex gap-1'>
                    <Button
                      variant='ghost'
                      size='sm'
                      aria-label={`Editar sección ${section.name}`}
                      onClick={() => setEditor({ kind: 'section', section })}
                    >
                      Editar
                    </Button>
                    <Button
                      variant='ghost'
                      size='sm'
                      aria-label={`Quitar sección ${section.name}`}
                      onClick={() =>
                        setAction({
                          title: 'Quitar sección',
                          description: `Se quitará «${section.name}». Sus productos seguirán en la carta, sin sección.`,
                          label: 'Quitar sección',
                          success: 'Sección eliminada.',
                          destructive: true,
                          run: () => http.delete(`/admin/sections/${section.id}`),
                          onSuccess: () => setSectionId('all'),
                        })
                      }
                    >
                      Quitar
                    </Button>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <p className='text-muted-foreground text-sm'>
              Agrupa los productos para ordenar la carta.
            </p>
          )}
        </section>
      </div>
      <section className='corner-exit-m bg-card space-y-5 border p-5 md:p-6'>
        <div className='flex flex-wrap items-center justify-between gap-3'>
          <div>
            <h2 className='text-xl font-semibold'>Productos</h2>
            <p className='text-muted-foreground text-sm'>
              {store.products.length} productos en la carta
            </p>
          </div>
          <Button onClick={() => setEditor({ kind: 'product' })}>Nuevo producto</Button>
        </div>
        <div className='grid gap-4 sm:grid-cols-2'>
          <TextField
            label='Buscar producto'
            type='search'
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
          <SelectField
            label='Filtrar por sección'
            value={sectionId}
            onChange={(event) => setSectionId(event.target.value)}
          >
            <option value='all'>Todas las secciones</option>
            <option value=''>Sin sección</option>
            {store.sections.map((section) => (
              <option key={section.id} value={section.id}>
                {section.name}
              </option>
            ))}
          </SelectField>
        </div>
        {products.length === 0 ? (
          <EmptyState
            icon={UtensilsCrossed}
            title={store.products.length ? 'Sin coincidencias' : 'La carta está vacía'}
            description={
              store.products.length
                ? 'Cambia los filtros para ver más productos.'
                : 'Añade el primer producto con su precio y disponibilidad.'
            }
          />
        ) : (
          <ul className='divide-y'>
            {products.map((product) => (
              <li
                key={product.id}
                className='flex flex-wrap items-center justify-between gap-4 py-4'
              >
                <div className='min-w-0 space-y-1'>
                  <p className='font-semibold'>{product.name}</p>
                  <p className='text-muted-foreground text-sm'>
                    {product.variants.length
                      ? `${product.variants.length} variantes`
                      : formatMoney(product.basePrice)}{' '}
                    · {product.stock === null ? 'Sin límite de stock' : `Stock: ${product.stock}`}
                  </p>
                  <StatusBadge active={product.isAvailable && product.stock !== 0}>
                    {!product.isAvailable
                      ? 'No disponible'
                      : product.stock === 0
                        ? 'Agotado'
                        : 'Disponible'}
                  </StatusBadge>
                </div>
                <div className='flex gap-2'>
                  <Button
                    variant='outline'
                    size='sm'
                    aria-label={`Editar producto ${product.name}`}
                    onClick={() => setEditor({ kind: 'product', product })}
                  >
                    Editar
                  </Button>
                  <Button
                    variant='ghost'
                    size='sm'
                    aria-label={`Quitar producto ${product.name}`}
                    onClick={() =>
                      setAction({
                        title: 'Quitar producto',
                        description: `«${product.name}» saldrá de la carta. Los pedidos anteriores no cambian.`,
                        label: 'Quitar producto',
                        success: 'Producto eliminado.',
                        destructive: true,
                        run: () => http.delete(`/admin/products/${product.id}`),
                      })
                    }
                  >
                    Quitar
                  </Button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
      <div className='flex flex-wrap items-center justify-between gap-4 border-t pt-5'>
        <p className='text-muted-foreground text-sm'>
          Para retirar el negocio, primero deben terminar sus pedidos en curso.
        </p>
        <Button
          variant='ghost'
          onClick={() =>
            setAction({
              title: 'Retirar negocio',
              description: `«${store.name}» se ocultará y dejará de recibir pedidos. Su historial se conserva.`,
              label: 'Retirar negocio',
              success: 'Negocio retirado.',
              destructive: true,
              run: () => http.delete(`/admin/stores/${store.id}`),
              onSuccess: () => {
                void navigate({ to: '/admin/catalog' })
              },
            })
          }
        >
          Retirar negocio
        </Button>
      </div>
      {editor?.kind === 'store' && (
        <StoreFormDialog store={store} onClose={handleClose} onSaved={handleClose} />
      )}
      {editor?.kind === 'schedule' && <ScheduleFormDialog store={store} onClose={handleClose} />}
      {editor?.kind === 'product' && (
        <ProductFormDialog store={store} product={editor.product} onClose={handleClose} />
      )}
      {editor?.kind === 'section' && (
        <SectionFormDialog storeId={store.id} section={editor.section} onClose={handleClose} />
      )}
      {action && <CatalogActionDialog action={action} onClose={() => setAction(null)} />}
    </div>
  )
}
