import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation } from '@tanstack/react-query'
import { Controller, useForm, useWatch } from 'react-hook-form'
import { toast } from 'sonner'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { CheckField, SelectField, TextField } from '@/components/shared/form-controls'
import { ImageUploadField } from '@/components/shared/image-upload-field'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import { useCatalogScope } from '../hooks/use-catalog-scope'
import type { Product, StoreDetail } from '../model/catalog'
import { saveProductMutation } from '../mutations/products.mutations'
import { ProductOptionsFields } from './product-options-fields'
import { ProductVariantsFields } from './product-variants-fields'
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
      variants: (product?.variants ?? []).map((v) => ({
        id: v.id,
        name: v.name,
        price: String(v.price.amount / 100),
        isAvailable: v.isAvailable,
      })),
      options: (product?.options ?? []).map((o) => ({
        id: o.id,
        name: o.name,
        minSelect: o.minSelect,
        maxSelect: o.maxSelect,
        values: o.values.map((v) => ({
          id: v.id,
          name: v.name,
          priceDelta: v.priceDelta.amount ? String(v.priceDelta.amount / 100) : '',
          isAvailable: v.isAvailable,
        })),
      })),
    },
  })
  const hasVariants = useWatch({ control: form.control, name: 'variants' }).length > 0
  const scope = useCatalogScope()
  const mutation = useMutation(saveProductMutation(store.id, product?.id, scope))
  const { errors, isSubmitting } = form.formState
  const submit = form.handleSubmit(async (values) => {
    try {
      await mutation.mutateAsync(productPayload(values, store.minOrderAmount.currency))
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
            readOnly={hasVariants}
            hint={hasVariants ? 'Con variantes se cobra el precio de la elegida.' : undefined}
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
          <Controller
            control={form.control}
            name='imageUrl'
            render={({ field, fieldState }) => (
              <ImageUploadField
                label='Foto (opcional)'
                hint='Cuadrada se ve mejor en la app.'
                value={field.value}
                onChange={(url) => field.onChange(url)}
                target={{ purpose: 'product', storeId: store.id }}
                error={fieldState.error?.message}
                disabled={isSubmitting}
              />
            )}
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
        <ProductVariantsFields form={form} disabled={isSubmitting} />
        <ProductOptionsFields form={form} disabled={isSubmitting} />
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
