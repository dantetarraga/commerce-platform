import { useSuspenseQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { RateFormDialog } from '@/components/shared/rate-form-dialog'
import { Button } from '@/components/ui/button'
import { formatRate } from '@/lib/percent'
import { saveStoreCommissionMutation } from '../mutations/stores.mutations'
import { storeCommissionQuery } from '../queries/catalog.queries'

/** Comisión de Apamuy para este negocio (solo admin). Suspende mientras carga. */
export function StoreCommissionCard({
  storeId,
  storeName,
}: {
  storeId: string
  storeName: string
}) {
  const { data: commission } = useSuspenseQuery(storeCommissionQuery(storeId))
  const [editing, setEditing] = useState(false)
  const own = commission.rateBps !== null
  return (
    <section className='corner-exit-m bg-card space-y-3 border p-5'>
      <div className='flex items-center justify-between gap-3'>
        <h2 className='text-xl font-semibold'>Comisión</h2>
        <Button variant='outline' size='sm' onClick={() => setEditing(true)}>
          Cambiar comisión
        </Button>
      </div>
      <p className='font-display text-2xl font-semibold tabular-nums'>
        {formatRate(commission.effectiveRateBps)}
      </p>
      <p className='text-muted-foreground text-sm'>
        {own
          ? `Comisión propia de este negocio. La de Apamuy es ${formatRate(commission.defaultRateBps)}.`
          : 'Usa la comisión por defecto de Apamuy.'}{' '}
        Se cobra sobre el subtotal de productos de cada pedido entregado.
      </p>
      {editing && (
        <RateFormDialog
          title={`Comisión de ${storeName}`}
          description='Se aplica a los pedidos nuevos de este negocio. Los pedidos ya hechos conservan la comisión con la que se crearon.'
          rateBps={commission.rateBps}
          defaultRateBps={commission.defaultRateBps}
          mutation={saveStoreCommissionMutation(storeId)}
          onClose={() => setEditing(false)}
        />
      )}
    </section>
  )
}
