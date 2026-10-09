import { useSuspenseQuery } from '@tanstack/react-query'
import { useNavigate } from '@tanstack/react-router'
import { useState } from 'react'
import { ConfirmActionDialog, type ConfirmAction } from '@/components/shared/confirm-action-dialog'
import { PageHeader } from '@/components/shared/page-header'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { deleteStoreMutation, toggleStorePublishedMutation } from '../mutations/stores.mutations'
import { storeQuery } from '../queries/catalog.queries'
import { StoreFormDialog } from './store-form'
import { StoreProductsCard } from './store-products-card'
import { StoreSchedulesCard } from './store-schedules-card'
import { StoreSectionsCard } from './store-sections-card'

/** Ficha de un negocio para el admin: datos, publicación, horarios y carta. Suspende mientras carga. */
export function StoreDetail({ storeId }: { storeId: string }) {
  const { data: store } = useSuspenseQuery(storeQuery(storeId))
  const navigate = useNavigate()
  const [editingStore, setEditingStore] = useState(false)
  const [action, setAction] = useState<ConfirmAction | null>(null)
  const handleClose = () => setEditingStore(false)
  function handlePublication() {
    setAction({
      title: store.isActive ? 'Pasar negocio a borrador' : 'Publicar negocio',
      description: store.isActive
        ? `${store.name} dejará de aparecer en la app del cliente. Sus pedidos actuales se conservan.`
        : `${store.name} aparecerá en la app. Revisa sus horarios, ubicación y productos antes de publicar.`,
      label: store.isActive ? 'Pasar a borrador' : 'Publicar',
      success: 'Publicación actualizada.',
      mutation: toggleStorePublishedMutation(store.id, store.isActive),
    })
  }
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Catálogo'
        title={store.name}
        description={store.addressLine}
        actions={
          <>
            <Button variant='outline' onClick={() => setEditingStore(true)}>
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
        <StoreSchedulesCard store={store} />
        <StoreSectionsCard store={store} />
      </div>
      <StoreProductsCard store={store} />
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
              mutation: deleteStoreMutation(store.id),
              onSuccess: () => {
                void navigate({ to: '/admin/catalog' })
              },
            })
          }
        >
          Retirar negocio
        </Button>
      </div>
      {editingStore && (
        <StoreFormDialog store={store} onClose={handleClose} onSaved={handleClose} />
      )}
      {action && <ConfirmActionDialog action={action} onClose={() => setAction(null)} />}
    </div>
  )
}
