import { useState } from 'react'
import { ConfirmActionDialog, type ConfirmAction } from '@/components/shared/confirm-action-dialog'
import { Button } from '@/components/ui/button'
import { useCatalogScope } from '../hooks/use-catalog-scope'
import type { MenuSection, StoreDetail } from '../model/catalog'
import { deleteSectionMutation } from '../mutations/sections.mutations'
import { SectionFormDialog } from './section-form'

/** Secciones de la carta: crear, renombrar y quitar. */
export function StoreSectionsCard({ store }: { store: StoreDetail }) {
  const scope = useCatalogScope()
  const [editor, setEditor] = useState<{ kind: 'section'; section?: MenuSection } | null>(null)
  const [action, setAction] = useState<ConfirmAction | null>(null)
  return (
    <>
      <section className='corner-exit-m bg-card space-y-4 border p-5'>
        <div className='flex items-center justify-between gap-3'>
          <h2 className='text-xl font-semibold'>Secciones de la carta</h2>
          <Button variant='outline' size='sm' onClick={() => setEditor({ kind: 'section' })}>
            Nueva sección
          </Button>
        </div>
        {store.sections.length ? (
          <ul className='space-y-2'>
            {store.sections.map((section) => (
              <li
                key={section.id}
                className='flex flex-wrap items-center justify-between gap-2 text-sm'
              >
                <span>{section.name}</span>
                <div className='flex gap-1'>
                  <Button
                    variant='ghost'
                    size='sm'
                    aria-label={`Editar sección ${section.name}`}
                    onClick={() => setEditor({ kind: 'section', section })}
                  >
                    Editar
                  </Button>
                  <Button
                    variant='ghost'
                    size='sm'
                    aria-label={`Quitar sección ${section.name}`}
                    onClick={() =>
                      setAction({
                        title: 'Quitar sección',
                        description: `Se quitará «${section.name}». Sus productos seguirán en la carta, sin sección.`,
                        label: 'Quitar sección',
                        success: 'Sección eliminada.',
                        destructive: true,
                        mutation: deleteSectionMutation(store.id, section.id, scope),
                      })
                    }
                  >
                    Quitar
                  </Button>
                </div>
              </li>
            ))}
          </ul>
        ) : (
          <p className='text-muted-foreground text-sm'>
            Agrupa los productos para ordenar la carta.
          </p>
        )}
      </section>
      {editor && (
        <SectionFormDialog
          storeId={store.id}
          section={editor.section}
          onClose={() => setEditor(null)}
        />
      )}
      {action && <ConfirmActionDialog action={action} onClose={() => setAction(null)} />}
    </>
  )
}
