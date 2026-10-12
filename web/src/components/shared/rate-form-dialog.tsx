import { useMutation, type UseMutationOptions } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { formatRate, parsePercent } from '@/lib/percent'
import { EditorDialog } from './editor-dialog'
import { TextField } from './form-controls'
import { ErrorNotice } from './query-feedback'

interface RateFormDialogProps<TData> {
  title: string
  description: string
  /** Puntos básicos actuales; null si usa la comisión por defecto. */
  rateBps: number | null
  /** Con él, el formulario permite volver a la comisión por defecto (envía `null`). */
  defaultRateBps?: number
  /** De `mutations/` del feature: guarda los puntos básicos (o `null`) e invalida. */
  mutation: UseMutationOptions<TData, Error, number | null>
  onClose: () => void
}

/** Edita una comisión en porcentaje (0 a 100 %, hasta dos decimales). */
export function RateFormDialog<TData>({
  title,
  description,
  rateBps,
  defaultRateBps,
  mutation: options,
  onClose,
}: RateFormDialogProps<TData>) {
  const [value, setValue] = useState(rateBps === null ? '' : String(rateBps / 100))
  const [invalid, setInvalid] = useState(false)
  const mutation = useMutation(options)

  async function save(next: number | null) {
    try {
      await mutation.mutateAsync(next)
      toast.success('Comisión guardada.')
      onClose()
    } catch {
      /* El error de la API queda en el formulario. */
    }
  }

  function handleSubmit(event: FormEvent) {
    event.preventDefault()
    const parsed = parsePercent(value)
    setInvalid(parsed === null)
    if (parsed !== null) void save(parsed)
  }

  return (
    <EditorDialog
      title={title}
      description={description}
      onClose={onClose}
      busy={mutation.isPending}
    >
      <form onSubmit={handleSubmit} noValidate className='space-y-5'>
        <div className='w-48'>
          <TextField
            label='Comisión (%)'
            inputMode='decimal'
            placeholder={defaultRateBps === undefined ? '10' : String(defaultRateBps / 100)}
            value={value}
            disabled={mutation.isPending}
            error={invalid ? 'Escribe un porcentaje de 0 a 100, como 10 o 12,5.' : undefined}
            onChange={(event) => setValue(event.target.value)}
          />
        </div>
        <ErrorNotice error={mutation.error} />
        <div className='flex flex-wrap justify-end gap-3'>
          {defaultRateBps !== undefined && rateBps !== null && (
            <Button
              type='button'
              variant='ghost'
              disabled={mutation.isPending}
              onClick={() => {
                void save(null)
              }}
            >
              Usar la de Apamuy ({formatRate(defaultRateBps)})
            </Button>
          )}
          <Button type='button' variant='outline' disabled={mutation.isPending} onClick={onClose}>
            Cancelar
          </Button>
          <Button type='submit' disabled={mutation.isPending}>
            {mutation.isPending ? 'Guardando…' : 'Guardar comisión'}
          </Button>
        </div>
      </form>
    </EditorDialog>
  )
}
