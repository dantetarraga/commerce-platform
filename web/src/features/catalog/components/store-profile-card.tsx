import { useState } from 'react'
import { ConfirmActionDialog, type ConfirmAction } from '@/components/shared/confirm-action-dialog'
import { SafeImage } from '@/components/shared/safe-image'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { formatMoney } from '@/lib/money'
import type { StoreDetail } from '../model/catalog'
import { toggleAcceptingOrdersMutation } from '../mutations/stores.mutations'
import { StoreProfileFormDialog } from './store-profile-form'

function Fact({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className='text-muted-foreground text-xs'>{label}</dt>
      <dd className='font-semibold'>{value}</dd>
    </div>
  )
}

/** Cómo ve el cliente el negocio, el interruptor de pedidos y sus datos editables. */
export function StoreProfileCard({ store }: { store: StoreDetail }) {
  const [editing, setEditing] = useState(false)
  const [action, setAction] = useState<ConfirmAction | null>(null)
  return (
    <section className='corner-exit-m bg-card overflow-hidden border'>
      {/* Más baja que el banner de la app: aquí es contexto, no la pieza principal. */}
      <SafeImage src={store.coverUrl ?? undefined} className='h-40 w-full object-cover md:h-52' />
      <div className='space-y-5 p-5 md:p-6'>
        <div className='flex flex-wrap items-start justify-between gap-4'>
          <div className='flex items-center gap-4'>
            <SafeImage
              src={store.logoUrl ?? undefined}
              className='size-16 shrink-0 rounded-full border object-cover'
            />
            <div className='space-y-1'>
              <h2 className='text-2xl font-semibold'>{store.name}</h2>
              <p className='text-muted-foreground text-sm'>{store.addressLine}</p>
            </div>
          </div>
          <div className='flex flex-wrap gap-2'>
            <Button variant='outline' onClick={() => setEditing(true)}>
              Editar datos
            </Button>
            <Button
              variant={store.isAcceptingOrders ? 'ghost' : 'default'}
              onClick={() =>
                setAction({
                  title: store.isAcceptingOrders ? 'Pausar pedidos' : 'Reanudar pedidos',
                  description: store.isAcceptingOrders
                    ? 'Los clientes verán el negocio cerrado hasta que lo reanudes. Los pedidos en curso siguen.'
                    : 'El negocio vuelve a recibir pedidos dentro de su horario.',
                  label: store.isAcceptingOrders ? 'Pausar' : 'Reanudar',
                  success: store.isAcceptingOrders ? 'Pedidos en pausa.' : 'Pedidos reanudados.',
                  destructive: store.isAcceptingOrders,
                  mutation: toggleAcceptingOrdersMutation(store.id, store.isAcceptingOrders),
                })
              }
            >
              {store.isAcceptingOrders ? 'Pausar pedidos' : 'Reanudar pedidos'}
            </Button>
          </div>
        </div>
        <div className='flex flex-wrap gap-2'>
          <StatusBadge active={store.isActive}>
            {store.isActive ? 'Publicado en la app' : 'En revisión por Apamuy'}
          </StatusBadge>
          <StatusBadge active={store.isAcceptingOrders}>
            {store.isAcceptingOrders ? 'Recibe pedidos según horario' : 'Pedidos en pausa'}
          </StatusBadge>
        </div>
        {store.description && <p className='text-sm'>{store.description}</p>}
        <dl className='grid grid-cols-2 gap-4 text-sm sm:grid-cols-3'>
          <Fact label='Teléfono' value={store.phone ?? 'Sin teléfono'} />
          <Fact label='Preparación' value={`${store.avgPrepMinutes} min`} />
          <Fact label='Pedido mínimo' value={formatMoney(store.minOrderAmount)} />
        </dl>
      </div>
      {editing && <StoreProfileFormDialog store={store} onClose={() => setEditing(false)} />}
      {action && <ConfirmActionDialog action={action} onClose={() => setAction(null)} />}
    </section>
  )
}
