import { X } from 'lucide-react'
import { Dialog } from 'radix-ui'
import type { ReactNode } from 'react'
import { Button } from '@/components/ui/button'

export function EditorDialog({
  title,
  description,
  children,
  onClose,
  busy = false,
}: {
  title: string
  description: string
  children: ReactNode
  onClose: () => void
  busy?: boolean
}) {
  return (
    <Dialog.Root
      open
      onOpenChange={(open) => {
        if (!open && !busy) onClose()
      }}
    >
      <Dialog.Portal>
        <Dialog.Overlay className='bg-foreground/40 fixed inset-0 z-50' />
        <Dialog.Content
          className='bg-card fixed top-1/2 left-1/2 z-50 max-h-[90dvh] w-[calc(100%-2rem)] max-w-2xl -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-xl border p-5 shadow-xl md:p-8'
          onInteractOutside={(event) => event.preventDefault()}
        >
          <div className='mb-6 flex items-start justify-between gap-4'>
            <div className='space-y-1'>
              <Dialog.Title className='text-2xl font-semibold'>{title}</Dialog.Title>
              <Dialog.Description className='text-muted-foreground text-sm'>
                {description}
              </Dialog.Description>
            </div>
            <Dialog.Close asChild>
              <Button type='button' variant='ghost' size='icon' disabled={busy} aria-label='Cerrar'>
                <X aria-hidden />
              </Button>
            </Dialog.Close>
          </div>
          {children}
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
