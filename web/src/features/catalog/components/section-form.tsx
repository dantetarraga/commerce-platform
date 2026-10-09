import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { TextField } from '@/components/shared/form-controls'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import { saveSectionMutation } from '../mutations/sections.mutations'
import type { MenuSection } from '../model/catalog'
import { sectionSchema, type SectionForm } from '../schemas/catalog.schemas'

export function SectionFormDialog({
  storeId,
  section,
  onClose,
}: {
  storeId: string
  section?: MenuSection
  onClose: () => void
}) {
  const form = useForm<SectionForm>({
    resolver: zodResolver(sectionSchema),
    defaultValues: { name: section?.name ?? '', sortOrder: section?.sortOrder ?? 0 },
  })
  const mutation = useMutation(saveSectionMutation(storeId, section?.id))
  const submit = form.handleSubmit(async (values) => {
    try {
      await mutation.mutateAsync(values)
      toast.success('Sección guardada.')
      onClose()
    } catch {
      /* Error presentado en el formulario. */
    }
  })
  const { errors, isSubmitting } = form.formState
  return (
    <EditorDialog
      title={section ? 'Editar sección' : 'Nueva sección'}
      description='Organiza la carta por entradas, platos, bebidas u otros grupos.'
      onClose={onClose}
      busy={isSubmitting}
    >
      <form onSubmit={submit} noValidate className='space-y-5'>
        <fieldset disabled={isSubmitting} className='space-y-4'>
          <TextField
            label='Nombre de la sección'
            error={errors.name?.message}
            {...form.register('name')}
          />
          <TextField
            label='Orden de la sección'
            type='number'
            min='0'
            error={errors.sortOrder?.message}
            {...form.register('sortOrder', { valueAsNumber: true })}
          />
        </fieldset>
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button type='button' variant='outline' disabled={isSubmitting} onClick={onClose}>
            Cancelar
          </Button>
          <Button type='submit' disabled={isSubmitting}>
            {isSubmitting ? 'Guardando…' : 'Guardar sección'}
          </Button>
        </div>
      </form>
    </EditorDialog>
  )
}
