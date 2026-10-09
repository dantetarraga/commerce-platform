import { UtensilsCrossed } from 'lucide-react'
import { useState } from 'react'
import { ConfirmActionDialog, type ConfirmAction } from '@/components/shared/confirm-action-dialog'
import { EmptyState } from '@/components/shared/empty-state'
import { SelectField, TextField } from '@/components/shared/form-controls'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { formatMoney } from '@/lib/money'
import { useCatalogScope } from '../hooks/use-catalog-scope'
import type { Product, StoreDetail } from '../model/catalog'
import { deleteProductMutation } from '../mutations/products.mutations'
import { ProductFormDialog } from './product-form'

/** Productos de la carta con búsqueda y filtro por sección. */
export function StoreProductsCard({ store }: { store: StoreDetail }) {
  const scope = useCatalogScope()
  const [editor, setEditor] = useState<{ kind: 'product'; product?: Product } | null>(null)
  const [action, setAction] = useState<ConfirmAction | null>(null)
  const [search, setSearch] = useState('')
  const [selectedSection, setSectionId] = useState('all')
  // Si quitaron la sección filtrada, se vuelve a mostrar todo.
  const sectionId =
    selectedSection === 'all' ||
    selectedSection === '' ||
    store.sections.some((section) => section.id === selectedSection)
      ? selectedSection
      : 'all'
  const products = store.products.filter(
    (product) =>
      product.name.toLocaleLowerCase('es-PE').includes(search.trim().toLocaleLowerCase('es-PE')) &&
      (sectionId === 'all' || (product.menuSectionId ?? '') === sectionId),
  )
  return (
    <>
      <section className='corner-exit-m bg-card space-y-5 border p-5 md:p-6'>
        <div className='flex flex-wrap items-center justify-between gap-3'>
          <div>
            <h2 className='text-xl font-semibold'>Productos</h2>
            <p className='text-muted-foreground text-sm'>
              {store.products.length} productos en la carta
            </p>
          </div>
          <Button onClick={() => setEditor({ kind: 'product' })}>Nuevo producto</Button>
        </div>
        <div className='grid gap-4 sm:grid-cols-2'>
          <TextField
            label='Buscar producto'
            type='search'
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
          <SelectField
            label='Filtrar por sección'
            value={sectionId}
            onChange={(event) => setSectionId(event.target.value)}
          >
            <option value='all'>Todas las secciones</option>
            <option value=''>Sin sección</option>
            {store.sections.map((section) => (
              <option key={section.id} value={section.id}>
                {section.name}
              </option>
            ))}
          </SelectField>
        </div>
        {products.length === 0 ? (
          <EmptyState
            icon={UtensilsCrossed}
            title={store.products.length ? 'Sin coincidencias' : 'La carta está vacía'}
            description={
              store.products.length
                ? 'Cambia los filtros para ver más productos.'
                : 'Añade el primer producto con su precio y disponibilidad.'
            }
          />
        ) : (
          <ul className='divide-y'>
            {products.map((product) => (
              <li
                key={product.id}
                className='flex flex-wrap items-center justify-between gap-4 py-4'
              >
                <div className='min-w-0 space-y-1'>
                  <p className='font-semibold'>{product.name}</p>
                  <p className='text-muted-foreground text-sm'>
                    {product.variants.length
                      ? `${product.variants.length} variantes`
                      : formatMoney(product.basePrice)}{' '}
                    · {product.stock === null ? 'Sin límite de stock' : `Stock: ${product.stock}`}
                  </p>
                  <StatusBadge active={product.isAvailable && product.stock !== 0}>
                    {!product.isAvailable
                      ? 'No disponible'
                      : product.stock === 0
                        ? 'Agotado'
                        : 'Disponible'}
                  </StatusBadge>
                </div>
                <div className='flex gap-2'>
                  <Button
                    variant='outline'
                    size='sm'
                    aria-label={`Editar producto ${product.name}`}
                    onClick={() => setEditor({ kind: 'product', product })}
                  >
                    Editar
                  </Button>
                  <Button
                    variant='ghost'
                    size='sm'
                    aria-label={`Quitar producto ${product.name}`}
                    onClick={() =>
                      setAction({
                        title: 'Quitar producto',
                        description: `«${product.name}» saldrá de la carta. Los pedidos anteriores no cambian.`,
                        label: 'Quitar producto',
                        success: 'Producto eliminado.',
                        destructive: true,
                        mutation: deleteProductMutation(store.id, product.id, scope),
                      })
                    }
                  >
                    Quitar
                  </Button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
      {editor && (
        <ProductFormDialog store={store} product={editor.product} onClose={() => setEditor(null)} />
      )}
      {action && <ConfirmActionDialog action={action} onClose={() => setAction(null)} />}
    </>
  )
}
