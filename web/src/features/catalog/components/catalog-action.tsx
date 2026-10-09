import { useMutation, type UseMutationOptions } from '@tanstack/react-query'
import { toast } from 'sonner'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'

export interface CatalogAction {
  title: string
  description: string
  label: string
  success: string
  destructive?: boolean
  /** De `mutations/`: hace el cambio e invalida lo que corresponde. */
  mutation: UseMutationOptions<void, Error, void>
  onSuccess?: () => void
}

export function CatalogActionDialog({
  action,
  onClose,
}: {
  action: CatalogAction
  onClose: () => void
}) {
  const mutation = useMutation(action.mutation)
  async function handleConfirm() {
    try {
      await mutation.mutateAsync()
      toast.success(action.success)
      onClose()
      action.onSuccess?.()
    } catch {
      /* Mantiene la confirmación con el error de la API. */
    }
  }
  return (
    <EditorDialog
      title={action.title}
      description={action.description}
      onClose={onClose}
      busy={mutation.isPending}
    >
      <div className='space-y-5'>
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button variant='outline' disabled={mutation.isPending} onClick={onClose}>
            Cancelar
          </Button>
          <Button
            variant={action.destructive ? 'destructive' : 'default'}
            disabled={mutation.isPending}
            onClick={handleConfirm}
          >
            {mutation.isPending ? 'Guardando…' : action.label}
          </Button>
        </div>
      </div>
    </EditorDialog>
  )
}
