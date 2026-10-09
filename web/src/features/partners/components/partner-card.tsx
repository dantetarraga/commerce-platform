import { useState } from 'react'
import { toast } from 'sonner'
import type { PartnerAccount } from '@/app/api/admin-lookups'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { CheckField } from '@/components/shared/form-controls'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { useSuspendPartner } from '../api/partners.api'
import type { PartnerRole } from '../schemas/partners.schemas'

const ROLE_NAMES: Record<string, string> = {
  ADMIN: 'Administrador',
  CUSTOMER: 'Cliente',
  MERCHANT: 'Negocio',
  COURIER: 'Repartidor',
}

function SuspendDialog({ account, onClose }: { account: PartnerAccount; onClose: () => void }) {
  const heldRoles = account.roles.filter(
    (role): role is PartnerRole => role === 'MERCHANT' || role === 'COURIER',
  )
  const [roles, setRoles] = useState(heldRoles)
  const mutation = useSuspendPartner()
  async function handleSuspend() {
    try {
      await mutation.mutateAsync({ id: account.id, roles })
      toast.success('Acceso de socio suspendido.')
      onClose()
    } catch {
      /* Se conserva la confirmación para corregir o reintentar. */
    }
  }
  return (
    <EditorDialog
      title='Suspender acceso de socio'
      description={`Selecciona qué acceso quitar a ${account.firstName} ${account.lastName}. Su cuenta de cliente se conserva.`}
      busy={mutation.isPending}
      onClose={onClose}
    >
      <div className='space-y-5'>
        {heldRoles.map((role) => (
          <CheckField
            key={role}
            checked={roles.includes(role)}
            disabled={mutation.isPending}
            onChange={(event) =>
              setRoles((current) =>
                event.target.checked
                  ? [...current, role]
                  : current.filter((value) => value !== role),
              )
            }
          >
            {ROLE_NAMES[role]}
          </CheckField>
        ))}
        <p className='text-muted-foreground text-sm'>
          Se cerrarán sus sesiones. Si suspendes Negocio, sus tiendas dejarán de recibir pedidos. Un
          repartidor con un pedido en curso no puede suspenderse.
        </p>
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button variant='outline' disabled={mutation.isPending} onClick={onClose}>
            Cancelar
          </Button>
          <Button
            variant='destructive'
            disabled={mutation.isPending || !roles.length}
            onClick={handleSuspend}
          >
            {mutation.isPending ? 'Suspendiendo…' : 'Confirmar suspensión'}
          </Button>
        </div>
      </div>
    </EditorDialog>
  )
}

export function PartnerCard({
  account,
  onEdit,
}: {
  account: PartnerAccount
  onEdit: (role: PartnerRole) => void
}) {
  const [suspending, setSuspending] = useState(false)
  const isPartner = account.roles.some((role) => role === 'MERCHANT' || role === 'COURIER')
  return (
    <section className='corner-exit-m bg-card space-y-6 border p-6'>
      <div className='flex flex-wrap items-start justify-between gap-4'>
        <div>
          <h2 className='text-2xl font-semibold'>
            {account.firstName} {account.lastName}
          </h2>
          <p className='text-muted-foreground mt-1'>+51 {account.phone}</p>
        </div>
        <StatusBadge active={account.isActive}>
          {account.isActive ? 'Cuenta activa' : 'Cuenta desactivada'}
        </StatusBadge>
      </div>
      <div className='flex flex-wrap gap-2'>
        {account.roles.map((role) => (
          <StatusBadge key={role}>{ROLE_NAMES[role] ?? role}</StatusBadge>
        ))}
      </div>
      <div className='grid gap-6 sm:grid-cols-2'>
        <div>
          <h3 className='mb-2 font-semibold'>Negocios vinculados</h3>
          {account.stores.length ? (
            <ul className='space-y-2'>
              {account.stores.map((store) => (
                <li
                  key={store.id}
                  className='flex flex-wrap items-center justify-between gap-2 text-sm'
                >
                  {store.name}
                  <StatusBadge active={store.isAcceptingOrders}>
                    {store.isAcceptingOrders ? 'Recibe pedidos' : 'En pausa'}
                  </StatusBadge>
                </li>
              ))}
            </ul>
          ) : (
            <p className='text-muted-foreground text-sm'>Sin negocios vinculados.</p>
          )}
        </div>
        <div>
          <h3 className='mb-2 font-semibold'>Repartidor</h3>
          <p className='text-muted-foreground text-sm'>
            {account.courier
              ? `${account.courier.vehicleLabel}${account.courier.plate ? ` · ${account.courier.plate}` : ''}`
              : 'Sin vehículo registrado.'}
          </p>
        </div>
      </div>
      <div className='flex flex-wrap gap-3 border-t pt-5'>
        <Button variant='outline' disabled={!account.isActive} onClick={() => onEdit('MERCHANT')}>
          {account.roles.includes('MERCHANT') ? 'Asignar negocios' : 'Dar acceso de negocio'}
        </Button>
        <Button variant='outline' disabled={!account.isActive} onClick={() => onEdit('COURIER')}>
          {account.roles.includes('COURIER') ? 'Editar repartidor' : 'Dar acceso de repartidor'}
        </Button>
        {isPartner && (
          <Button variant='destructive' onClick={() => setSuspending(true)}>
            Suspender socio
          </Button>
        )}
      </div>
      {suspending && <SuspendDialog account={account} onClose={() => setSuspending(false)} />}
    </section>
  )
}
