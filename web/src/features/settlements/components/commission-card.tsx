import { useSuspenseQuery } from '@tanstack/react-query'
import { Percent } from 'lucide-react'
import { useState } from 'react'
import { RateFormDialog } from '@/components/shared/rate-form-dialog'
import { Button } from '@/components/ui/button'
import { dateTime } from '@/lib/datetime'
import { formatRate } from '@/lib/percent'
import { saveCommissionMutation } from '../mutations/settlements.mutations'
import { commissionQuery } from '../queries/settlements.queries'

/** Comisión por defecto de Apamuy, con su editor. Suspende mientras carga. */
export function CommissionCard() {
  const { data: commission } = useSuspenseQuery(commissionQuery)
  const [editing, setEditing] = useState(false)
  return (
    <section className='corner-exit-m bg-card flex flex-wrap items-center justify-between gap-4 border p-5'>
      <div className='flex items-start gap-3'>
        <Percent className='text-primary mt-1 size-5 shrink-0' aria-hidden />
        <div>
          <h2 className='text-lg font-semibold'>
            Comisión por defecto:{' '}
            <span className='tabular-nums'>{formatRate(commission.rateBps)}</span>
          </h2>
          <p className='text-muted-foreground text-sm'>
            Sobre el subtotal de productos, sin envío ni propina. Cada negocio puede tener la suya
            en su ficha del catálogo.
            {commission.updatedBy && commission.updatedAt && (
              <>
                {' '}
                Cambiada por {commission.updatedBy.name} el{' '}
                {dateTime.formatDateTime(commission.updatedAt)}.
              </>
            )}
          </p>
        </div>
      </div>
      <Button variant='outline' onClick={() => setEditing(true)}>
        Cambiar comisión
      </Button>
      {editing && (
        <RateFormDialog
          title='Comisión por defecto'
          description='Se aplica a los pedidos nuevos de los negocios sin comisión propia. Los pedidos ya hechos conservan la suya.'
          rateBps={commission.rateBps}
          mutation={saveCommissionMutation()}
          onClose={() => setEditing(false)}
        />
      )}
    </section>
  )
}
