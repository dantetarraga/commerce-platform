import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { http } from '@/app/api'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { CheckField, SelectField, TextField } from '@/components/shared/form-controls'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import { formatMoney } from '@/lib/money'
import { useCatalogMutation } from '../api/catalog.api'
import type { Product, StoreDetail } from '../model/catalog'
import { productPayload, productSchema, type ProductForm } from '../schemas/catalog.schemas'

export function ProductFormDialog({
  store,
  product,
  onClose,
}: {
  store: StoreDetail
  product?: Product
  onClose: () => void
}) {
  const form = useForm<ProductForm>({
    resolver: zodResolver(productSchema),
    defaultValues: {
      name: product?.name ?? '',
      description: product?.description ?? '',
      imageUrl: product?.imageUrl ?? '',
      basePrice: String((product?.basePrice.amount ?? 0) / 100),
      menuSectionId: product?.menuSectionId ?? '',
      stock: product?.stock == null ? '' : String(product.stock),
      sortOrder: product?.sortOrder ?? 0,
      isAvailable: product?.isAvailable ?? true,
      isFeatured: product?.isFeatured ?? false,
      isLocal: product?.isLocal ?? false,
    },
  })
  const mutation = useCatalogMutation(async (values: ProductForm) => {
    const payload = productPayload(values, store.minOrderAmount.currency)
    return product
      ? http.patch(`/admin/products/${product.id}`, payload)
      : http.post(`/admin/stores/${store.id}/products`, payload)
  })
  const { errors, isSubmitting } = form.formState
  const submit = form.handleSubmit(async (values) => {
    try {
      await mutation.mutateAsync(values)
      toast.success('Producto guardado.')
      onClose()
    } catch {
      /* Error visible, sin perder el formulario. */
    }
  })
  return (
    <EditorDialog
      title={product ? 'Editar producto' : 'Nuevo producto'}
      description={`Carta de ${store.name}. Importes en soles.`}
      onClose={onClose}
      busy={isSubmitting}
    >
      <form onSubmit={submit} noValidate className='space-y-5'>
        <fieldset disabled={isSubmitting} className='grid gap-4 sm:grid-cols-2'>
          <TextField
            label='Nombre del producto'
            error={errors.name?.message}
            {...form.register('name')}
          />
          <SelectField label='Sección' {...form.register('menuSectionId')}>
            <option value=''>Sin sección</option>
            {store.sections.map((section) => (
              <option key={section.id} value={section.id}>
                {section.name}
              </option>
            ))}
          </SelectField>
          <TextField
            label='Precio base (S/)'
            inputMode='decimal'
            readOnly={Boolean(product?.variants.length)}
            hint={
              product?.variants.length ? 'Se cobra el precio de la variante elegida.' : undefined
            }
            error={errors.basePrice?.message}
            {...form.register('basePrice')}
          />
          <TextField
            label='Stock (opcional)'
            inputMode='numeric'
            hint='Vacío: sin límite. Cero: agotado.'
            error={errors.stock?.message}
            {...form.register('stock')}
          />
          <TextField
            label='Foto (URL https, opcional)'
            type='url'
            error={errors.imageUrl?.message}
            {...form.register('imageUrl')}
          />
          <TextField
            label='Orden en la carta'
            type='number'
            min='0'
            error={errors.sortOrder?.message}
            {...form.register('sortOrder', { valueAsNumber: true })}
          />
          <div className='sm:col-span-2'>
            <TextField
              label='Descripción (opcional)'
              error={errors.description?.message}
              {...form.register('description')}
            />
          </div>
          <CheckField {...form.register('isAvailable')}>Disponible</CheckField>
          <CheckField {...form.register('isFeatured')}>Destacado</CheckField>
          <CheckField {...form.register('isLocal')}>Hecho en la ciudad</CheckField>
        </fieldset>
        {product && (product.variants.length > 0 || product.options.length > 0) && (
          <div className='bg-secondary space-y-2 rounded-lg p-4 text-sm'>
            <h3 className='font-semibold'>Variantes y opciones actuales</h3>
            <p className='text-muted-foreground'>
              Solo consulta. Se conservan al guardar estos datos.
            </p>
            {product.variants.map((variant) => (
              <p key={variant.id}>
                {variant.name} · {formatMoney(variant.price)}
                {!variant.isAvailable && ' · No disponible'}
              </p>
            ))}
            {product.options.map((option) => (
              <p key={option.id}>
                {option.name}: {option.values.map((value) => value.name).join(', ')}
              </p>
            ))}
          </div>
        )}
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button type='button' variant='outline' disabled={isSubmitting} onClick={onClose}>
            Cancelar
          </Button>
          <Button type='submit' disabled={isSubmitting}>
            {isSubmitting ? 'Guardando…' : 'Guardar producto'}
          </Button>
        </div>
      </form>
    </EditorDialog>
  )
}
