import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { TextField } from '@/components/shared/form-controls'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import type { StoreDetail } from '../model/catalog'
import { saveStoreProfileMutation } from '../mutations/stores.mutations'
import {
  storeProfilePayload,
  storeProfileSchema,
  type StoreProfileForm,
} from '../schemas/catalog.schemas'

/** Datos que el dueño cambia de su negocio. Nombre y dirección los cambia Apamuy. */
export function StoreProfileFormDialog({
  store,
  onClose,
}: {
  store: StoreDetail
  onClose: () => void
}) {
  const form = useForm<StoreProfileForm>({
    resolver: zodResolver(storeProfileSchema),
    defaultValues: {
      description: store.description ?? '',
      phone: store.phone ?? '',
      logoUrl: store.logoUrl ?? '',
      coverUrl: store.coverUrl ?? '',
      minOrderAmount: String(store.minOrderAmount.amount / 100),
      avgPrepMinutes: store.avgPrepMinutes,
    },
  })
  const mutation = useMutation(saveStoreProfileMutation(store.id))
  const { errors, isSubmitting } = form.formState
  const submit = form.handleSubmit(async (values) => {
    try {
      await mutation.mutateAsync(storeProfilePayload(values, store.minOrderAmount.currency))
      toast.success('Datos del negocio guardados.')
      onClose()
    } catch {
      /* Error visible debajo del formulario. */
    }
  })
  return (
    <EditorDialog
      title='Datos del negocio'
      description='Para cambiar el nombre o la dirección, escríbenos: lo revisa el equipo Apamuy.'
      onClose={onClose}
      busy={isSubmitting}
    >
      <form onSubmit={submit} noValidate className='space-y-5'>
        <fieldset disabled={isSubmitting} className='space-y-4'>
          <TextField
            label='Descripción'
            hint='Lo que ve el cliente bajo el nombre.'
            error={errors.description?.message}
            {...form.register('description')}
          />
          <div className='grid gap-4 sm:grid-cols-2'>
            <TextField
              label='Teléfono del local'
              type='tel'
              error={errors.phone?.message}
              {...form.register('phone')}
            />
            <TextField
              label='Tiempo de preparación (min)'
              type='number'
              min='1'
              error={errors.avgPrepMinutes?.message}
              {...form.register('avgPrepMinutes', { valueAsNumber: true })}
            />
            <TextField
              label='Pedido mínimo (S/)'
              inputMode='decimal'
              error={errors.minOrderAmount?.message}
              {...form.register('minOrderAmount')}
            />
          </div>
          <TextField
            label='Logo (URL https)'
            error={errors.logoUrl?.message}
            {...form.register('logoUrl')}
          />
          <TextField
            label='Portada (URL https)'
            error={errors.coverUrl?.message}
            {...form.register('coverUrl')}
          />
        </fieldset>
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button type='button' variant='outline' disabled={isSubmitting} onClick={onClose}>
            Cancelar
          </Button>
          <Button type='submit' disabled={isSubmitting}>
            {isSubmitting ? 'Guardando…' : 'Guardar datos'}
          </Button>
        </div>
      </form>
    </EditorDialog>
  )
}
