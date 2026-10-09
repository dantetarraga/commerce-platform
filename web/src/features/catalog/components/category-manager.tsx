import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation, useSuspenseQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { TextField } from '@/components/shared/form-controls'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import type { Category } from '../model/catalog'
import { saveCategoryMutation } from '../mutations/categories.mutations'
import { categoriesQuery } from '../queries/catalog.queries'
import { categorySchema, type CategoryForm } from '../schemas/catalog.schemas'
import { CategoriesSkeleton } from './catalog-skeletons'

function CategoryEditor({ category, onClose }: { category?: Category; onClose: () => void }) {
  const form = useForm<CategoryForm>({
    resolver: zodResolver(categorySchema),
    defaultValues: { name: category?.name ?? '', iconUrl: category?.iconUrl ?? '' },
  })
  const mutation = useMutation(saveCategoryMutation(category?.id))
  const submit = form.handleSubmit(async (values) => {
    try {
      await mutation.mutateAsync({ ...values, iconUrl: values.iconUrl || null })
      toast.success('Categoría guardada.')
      onClose()
    } catch {
      /* Error presentado en el formulario. */
    }
  })
  const { errors, isSubmitting } = form.formState
  return (
    <EditorDialog
      title={category ? 'Editar categoría' : 'Nueva categoría'}
      description='Las categorías se comparten entre todos los negocios.'
      onClose={onClose}
      busy={isSubmitting}
    >
      <form onSubmit={submit} noValidate className='space-y-5'>
        <fieldset disabled={isSubmitting} className='space-y-4'>
          <TextField
            label='Nombre de la categoría'
            error={errors.name?.message}
            {...form.register('name')}
          />
          <TextField
            label='Ícono (URL https, opcional)'
            error={errors.iconUrl?.message}
            {...form.register('iconUrl')}
          />
        </fieldset>
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button type='button' variant='outline' disabled={isSubmitting} onClick={onClose}>
            Cancelar
          </Button>
          <Button type='submit' disabled={isSubmitting}>
            {isSubmitting ? 'Guardando…' : 'Guardar categoría'}
          </Button>
        </div>
      </form>
    </EditorDialog>
  )
}

export function CategoryManager() {
  const [editing, setEditing] = useState<Category | 'new' | null>(null)
  return (
    <section className='corner-exit-m bg-card space-y-5 border p-5 md:p-6'>
      <div className='flex flex-wrap items-center justify-between gap-3'>
        <div>
          <h2 className='text-xl font-semibold'>Categorías</h2>
          <p className='text-muted-foreground text-sm'>Ayuda a encontrar cada negocio en la app.</p>
        </div>
        <Button variant='outline' onClick={() => setEditing('new')}>
          Nueva categoría
        </Button>
      </div>
      <QueryBoundary fallback={<CategoriesSkeleton />}>
        <CategoryList onEdit={setEditing} />
      </QueryBoundary>
      {editing && (
        <CategoryEditor
          category={editing === 'new' ? undefined : editing}
          onClose={() => setEditing(null)}
        />
      )}
    </section>
  )
}

function CategoryList({ onEdit }: { onEdit: (category: Category) => void }) {
  const { data: categories } = useSuspenseQuery(categoriesQuery)
  if (categories.length === 0) {
    return <p className='text-muted-foreground text-sm'>Todavía no hay categorías.</p>
  }
  return (
    <ul className='grid gap-3 sm:grid-cols-2 lg:grid-cols-3'>
      {categories.map((category) => (
        <li
          key={category.id}
          className='flex items-center justify-between gap-2 rounded-lg border p-3'
        >
          <span className='text-sm font-semibold'>{category.name}</span>
          <Button
            size='sm'
            variant='ghost'
            aria-label={`Editar categoría ${category.name}`}
            onClick={() => onEdit(category)}
          >
            Editar
          </Button>
        </li>
      ))}
    </ul>
  )
}
