import { useNavigate } from '@tanstack/react-router'
import { useState } from 'react'
import { PageHeader } from '@/components/shared/page-header'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { Button } from '@/components/ui/button'
import { StoresDirectorySkeleton } from '../components/catalog-skeletons'
import { CategoryManager } from '../components/category-manager'
import { StoreFormDialog } from '../components/store-form'
import { StoresDirectory } from '../components/stores-directory'

export function CatalogPage() {
  const [creating, setCreating] = useState(false)
  const navigate = useNavigate()
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Catálogo'
        description='Negocios y cartas que tus clientes encuentran en Apamuy.'
        actions={<Button onClick={() => setCreating(true)}>Nuevo negocio</Button>}
      />
      {/* Cabecera y acciones se ven al instante; cada bloque espera sus datos por separado. */}
      <section className='corner-exit-m bg-card border p-5 md:p-6'>
        <QueryBoundary fallback={<StoresDirectorySkeleton />}>
          <StoresDirectory />
        </QueryBoundary>
      </section>
      <CategoryManager />
      {creating && (
        <StoreFormDialog
          onClose={() => setCreating(false)}
          onSaved={(storeId) => {
            setCreating(false)
            void navigate({ to: '/admin/catalog/$storeId', params: { storeId } })
          }}
        />
      )}
    </div>
  )
}
