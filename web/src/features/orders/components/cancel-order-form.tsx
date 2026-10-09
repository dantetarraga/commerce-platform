import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { TextField } from '@/components/shared/form-controls'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import { cancelOrderMutation } from '../mutations/orders.mutations'
import {
  CANCEL_REASONS,
  cancelOrderSchema,
  type CancelOrderValues,
} from '../schemas/orders.schemas'

interface CancelOrderFormProps {
  orderId: string
  onDone: () => void
  onBack: () => void
}

/** El motivo lo ve el cliente en su aviso. Devuelve stock y cupón. */
export function CancelOrderForm({ orderId, onDone, onBack }: CancelOrderFormProps) {
  const form = useForm<CancelOrderValues>({
    resolver: zodResolver(cancelOrderSchema),
    defaultValues: { reason: '' },
  })
  const mutation = useMutation(cancelOrderMutation(orderId))
  const { errors, isSubmitting } = form.formState
  const submit = form.handleSubmit(async ({ reason }) => {
    try {
      await mutation.mutateAsync(reason)
      toast.success('Pedido cancelado. Avisamos al cliente.')
      onDone()
    } catch {
      /* El error queda visible: p. ej. el pedido ya salió en camino. */
    }
  })
  return (
    <form
      onSubmit={submit}
      noValidate
      className='border-destructive/30 bg-destructive/5 space-y-4 rounded-lg border p-4'
    >
      <p className='font-semibold'>Cancelar el pedido</p>
      <div className='flex flex-wrap gap-2'>
        {CANCEL_REASONS.map((reason) => (
          <Button
            key={reason}
            type='button'
            variant='outline'
            size='sm'
            disabled={isSubmitting}
            onClick={() => form.setValue('reason', reason, { shouldValidate: true })}
          >
            {reason}
          </Button>
        ))}
      </div>
      <TextField
        label='Motivo (lo verá el cliente)'
        disabled={isSubmitting}
        error={errors.reason?.message}
        {...form.register('reason')}
      />
      <ErrorNotice error={mutation.error} />
      <div className='flex justify-end gap-3'>
        <Button type='button' variant='outline' disabled={isSubmitting} onClick={onBack}>
          Volver
        </Button>
        <Button type='submit' variant='destructive' disabled={isSubmitting}>
          {isSubmitting ? 'Cancelando…' : 'Cancelar pedido'}
        </Button>
      </div>
    </form>
  )
}
