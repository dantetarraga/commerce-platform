import { useMutation } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { useState } from 'react'
import { toast } from 'sonner'
import { ConfirmActionDialog, type ConfirmAction } from '@/components/shared/confirm-action-dialog'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { TextField } from '@/components/shared/form-controls'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import { ROLE_LABEL, suspendedPartnerRoles, type UserDetail } from '../model/users'
import {
  blockUserMutation,
  restorePartnerMutation,
  revokeSessionsMutation,
  setAdminMutation,
  unblockUserMutation,
} from '../mutations/users.mutations'

/** Las acciones sobre la cuenta. Cada una pide confirmación y queda en el historial. */
export function UserActions({ user }: { user: UserDetail }) {
  const [confirm, setConfirm] = useState<ConfirmAction | null>(null)
  const [blocking, setBlocking] = useState(false)
  const isAdmin = user.roles.includes('ADMIN')
  const restorable = suspendedPartnerRoles(user)

  return (
    <div className='flex flex-wrap gap-2'>
      <Button asChild variant='outline'>
        <Link to='/admin/partners'>Dar de alta como socio</Link>
      </Button>
      {restorable.length > 0 && user.isActive && (
        <Button
          variant='outline'
          onClick={() =>
            setConfirm({
              title: 'Reactivar socio',
              description: `Vuelve a ser ${restorable.map((r) => ROLE_LABEL[r].toLowerCase()).join(' y ')}. Sus negocios siguen en pausa hasta que los abra.`,
              label: 'Reactivar',
              success: 'Socio reactivado.',
              mutation: restorePartnerMutation(user.id, restorable),
            })
          }
        >
          Reactivar socio
        </Button>
      )}
      {user.activeSessions > 0 && (
        <Button
          variant='outline'
          onClick={() =>
            setConfirm({
              title: 'Cerrar sesiones',
              description:
                'Tendrá que volver a entrar con su celular en todos sus teléfonos y navegadores.',
              label: 'Cerrar sesiones',
              success: 'Sesiones cerradas.',
              mutation: revokeSessionsMutation(user.id),
            })
          }
        >
          Cerrar sesiones
        </Button>
      )}
      {user.isActive && (
        <Button
          variant='outline'
          onClick={() =>
            setConfirm({
              title: isAdmin ? 'Quitar acceso de admin' : 'Dar acceso de admin',
              description: isAdmin
                ? 'Deja de entrar al panel de administración y se cierran sus sesiones.'
                : 'Podrá ver y cambiar todo en el panel: pedidos, socios, catálogo, caja y usuarios.',
              label: isAdmin ? 'Quitar acceso' : 'Dar acceso',
              success: isAdmin ? 'Ya no es admin.' : 'Ahora es admin.',
              destructive: isAdmin,
              mutation: setAdminMutation(user.id, !isAdmin),
            })
          }
        >
          {isAdmin ? 'Quitar acceso de admin' : 'Dar acceso de admin'}
        </Button>
      )}
      {user.isActive ? (
        !isAdmin && (
          <Button variant='destructive' onClick={() => setBlocking(true)}>
            Bloquear cuenta
          </Button>
        )
      ) : (
        <Button
          onClick={() =>
            setConfirm({
              title: 'Desbloquear cuenta',
              description:
                'Podrá volver a entrar. Si era socio, se reactiva aparte desde esta misma ficha.',
              label: 'Desbloquear',
              success: 'Cuenta desbloqueada.',
              mutation: unblockUserMutation(user.id),
            })
          }
        >
          Desbloquear
        </Button>
      )}
      {confirm && <ConfirmActionDialog action={confirm} onClose={() => setConfirm(null)} />}
      {blocking && <BlockDialog user={user} onClose={() => setBlocking(false)} />}
    </div>
  )
}

function BlockDialog({ user, onClose }: { user: UserDetail; onClose: () => void }) {
  const [reason, setReason] = useState('')
  const mutation = useMutation(blockUserMutation(user.id))
  async function handleBlock() {
    try {
      await mutation.mutateAsync(reason.trim())
      toast.success('Cuenta bloqueada.')
      onClose()
    } catch {
      /* El error se muestra en el diálogo. */
    }
  }
  return (
    <EditorDialog
      title='Bloquear cuenta'
      description='No podrá entrar y se cierran sus sesiones. Si es socio, sus negocios quedan en pausa y deja de recibir repartos.'
      onClose={onClose}
      busy={mutation.isPending}
    >
      <div className='space-y-5'>
        <TextField
          label='Motivo (opcional)'
          placeholder='Ej.: pedidos falsos'
          maxLength={200}
          value={reason}
          onChange={(event) => setReason(event.target.value)}
        />
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button variant='outline' disabled={mutation.isPending} onClick={onClose}>
            Cancelar
          </Button>
          <Button variant='destructive' disabled={mutation.isPending} onClick={handleBlock}>
            {mutation.isPending ? 'Bloqueando…' : 'Bloquear'}
          </Button>
        </div>
      </div>
    </EditorDialog>
  )
}
