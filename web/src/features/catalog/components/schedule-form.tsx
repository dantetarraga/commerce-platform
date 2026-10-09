import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation } from '@tanstack/react-query'
import { useFieldArray, useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { SelectField, TextField } from '@/components/shared/form-controls'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import { minutesToTime, WEEK_DAYS, type StoreDetail } from '../model/catalog'
import { saveSchedulesMutation } from '../mutations/stores.mutations'
import { scheduleSchema, schedulesPayload, type ScheduleForm } from '../schemas/catalog.schemas'

export function ScheduleFormDialog({
  store,
  onClose,
}: {
  store: StoreDetail
  onClose: () => void
}) {
  const form = useForm<ScheduleForm>({
    resolver: zodResolver(scheduleSchema),
    defaultValues: {
      schedules: store.schedules.map((schedule) => ({
        ...schedule,
        opensAt: minutesToTime(schedule.opensAt),
        closesAt: minutesToTime(schedule.closesAt),
      })),
    },
  })
  const { fields, append, remove } = useFieldArray({ control: form.control, name: 'schedules' })
  const mutation = useMutation(saveSchedulesMutation(store.id))
  const submit = form.handleSubmit(async (values) => {
    try {
      await mutation.mutateAsync(schedulesPayload(values))
      toast.success('Horarios guardados.')
      onClose()
    } catch {
      /* El backend también valida turnos que se cruzan. */
    }
  })
  const { errors, isSubmitting } = form.formState
  return (
    <EditorDialog
      title='Horarios de atención'
      description='Hora local del negocio. Los días sin turnos quedan cerrados. Si el cierre es anterior a la apertura, el turno termina al día siguiente.'
      onClose={onClose}
      busy={isSubmitting}
    >
      <form onSubmit={submit} noValidate className='space-y-5'>
        <fieldset disabled={isSubmitting} className='space-y-4'>
          {fields.map((field, index) => (
            <div key={field.id} className='grid gap-3 rounded-lg border p-3 sm:grid-cols-3'>
              <SelectField
                label={`Día del turno ${index + 1}`}
                {...form.register(`schedules.${index}.dayOfWeek`, { valueAsNumber: true })}
              >
                {WEEK_DAYS.map((day, dayIndex) => (
                  <option value={dayIndex} key={day}>
                    {day}
                  </option>
                ))}
              </SelectField>
              <TextField
                label={`Apertura ${index + 1}`}
                placeholder='09:00'
                error={errors.schedules?.[index]?.opensAt?.message}
                {...form.register(`schedules.${index}.opensAt`)}
              />
              <TextField
                label={`Cierre ${index + 1}`}
                placeholder='22:00'
                error={errors.schedules?.[index]?.closesAt?.message}
                {...form.register(`schedules.${index}.closesAt`)}
              />
              <Button
                type='button'
                size='sm'
                variant='ghost'
                className='justify-self-start'
                onClick={() => remove(index)}
                aria-label={`Quitar turno ${index + 1}`}
              >
                Quitar turno
              </Button>
            </div>
          ))}
          {fields.length === 0 && (
            <p className='text-muted-foreground text-sm'>
              Sin horarios: el negocio no aparecerá abierto en la app.
            </p>
          )}
          <Button
            type='button'
            variant='outline'
            disabled={fields.length >= 28}
            onClick={() => append({ dayOfWeek: 1, opensAt: '09:00', closesAt: '22:00' })}
          >
            Añadir turno
          </Button>
          <p className='text-muted-foreground text-sm'>
            Usa HH:mm; 24:00 indica medianoche al final del día.
          </p>
        </fieldset>
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button type='button' variant='outline' disabled={isSubmitting} onClick={onClose}>
            Cancelar
          </Button>
          <Button type='submit' disabled={isSubmitting}>
            {isSubmitting ? 'Guardando…' : 'Guardar horarios'}
          </Button>
        </div>
      </form>
    </EditorDialog>
  )
}
