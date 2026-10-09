import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation, useQuery } from '@tanstack/react-query'
import { useForm, useWatch } from 'react-hook-form'
import { toast } from 'sonner'
import { citiesQuery } from '@/app/api/lookups'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { CheckField, SelectField, TextField } from '@/components/shared/form-controls'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import type { StoreDetail } from '../model/catalog'
import { saveStoreMutation } from '../mutations/stores.mutations'
import { categoriesQuery } from '../queries/catalog.queries'
import { storePayload, storeSchema, type StoreForm } from '../schemas/catalog.schemas'
import { OwnerPicker } from './owner-picker'

export function StoreFormDialog({
  store,
  onClose,
  onSaved,
}: {
  store?: StoreDetail
  onClose: () => void
  onSaved: (id: string) => void
}) {
  const cities = useQuery(citiesQuery)
  const categories = useQuery(categoriesQuery)
  const form = useForm<StoreForm>({
    resolver: zodResolver(storeSchema),
    defaultValues: {
      cityId: store?.cityId ?? '',
      ownerId: store?.ownerId ?? '',
      name: store?.name ?? '',
      addressLine: store?.addressLine ?? '',
      latitude: store?.latitude,
      longitude: store?.longitude,
      description: store?.description ?? '',
      phone: store?.phone ?? '',
      logoUrl: store?.logoUrl ?? '',
      coverUrl: store?.coverUrl ?? '',
      minOrderAmount: String((store?.minOrderAmount.amount ?? 0) / 100),
      avgPrepMinutes: store?.avgPrepMinutes ?? 20,
      categoryIds: store?.categoryIds ?? [],
    },
  })
  const ownerId = useWatch({ control: form.control, name: 'ownerId' })
  const categoryIds = useWatch({ control: form.control, name: 'categoryIds' })
  const mutation = useMutation(saveStoreMutation(store?.id))
  const { errors, isSubmitting } = form.formState
  const submit = form.handleSubmit(async (values) => {
    try {
      const currency =
        store?.minOrderAmount.currency ??
        cities.data?.find((city) => city.id === values.cityId)?.currency ??
        'PEN'
      const saved = await mutation.mutateAsync(storePayload(values, currency))
      toast.success(store ? 'Negocio actualizado.' : 'Negocio creado como borrador.')
      onSaved(saved.id)
    } catch {
      /* Error presentado debajo del formulario. */
    }
  })
  return (
    <EditorDialog
      title={store ? 'Editar negocio' : 'Nuevo negocio'}
      description='Completa los datos del local. Los negocios nuevos se guardan como borrador.'
      onClose={onClose}
      busy={isSubmitting}
    >
      <form onSubmit={submit} noValidate className='space-y-5'>
        <fieldset disabled={isSubmitting} className='space-y-5'>
          <OwnerPicker
            value={ownerId}
            error={errors.ownerId?.message}
            onChange={(id) =>
              form.setValue('ownerId', id, { shouldValidate: true, shouldDirty: true })
            }
          />
          {store && ownerId !== store.ownerId && (
            <p className='bg-primary-soft text-primary rounded-lg p-3 text-sm'>
              Al guardar, el nuevo dueño recibirá acceso al negocio y el anterior lo perderá.
            </p>
          )}
          <div className='grid gap-4 sm:grid-cols-2'>
            <TextField
              label='Nombre del negocio'
              error={errors.name?.message}
              {...form.register('name')}
            />
            <SelectField
              label='Ciudad'
              disabled={Boolean(store)}
              error={errors.cityId?.message}
              {...form.register('cityId')}
            >
              <option value=''>Elige una ciudad</option>
              {store && !cities.data?.some((city) => city.id === store.cityId) && (
                <option value={store.cityId}>Ciudad actual</option>
              )}
              {cities.data?.map((city) => (
                <option key={city.id} value={city.id}>
                  {city.name}
                </option>
              ))}
            </SelectField>
            <TextField
              label='Dirección del local'
              error={errors.addressLine?.message}
              {...form.register('addressLine')}
            />
            <TextField
              label='Celular del local (opcional)'
              type='tel'
              error={errors.phone?.message}
              {...form.register('phone')}
            />
            <TextField
              label='Latitud'
              type='number'
              step='any'
              placeholder='-14.79'
              error={errors.latitude?.message}
              {...form.register('latitude', { valueAsNumber: true })}
            />
            <TextField
              label='Longitud'
              type='number'
              step='any'
              placeholder='-71.41'
              error={errors.longitude?.message}
              {...form.register('longitude', { valueAsNumber: true })}
            />
            <TextField
              label='Preparación (minutos)'
              type='number'
              min='1'
              max='180'
              error={errors.avgPrepMinutes?.message}
              {...form.register('avgPrepMinutes', { valueAsNumber: true })}
            />
            <TextField
              label='Pedido mínimo (S/)'
              inputMode='decimal'
              error={errors.minOrderAmount?.message}
              {...form.register('minOrderAmount')}
            />
            <TextField
              label='Logo (URL https, opcional)'
              type='url'
              error={errors.logoUrl?.message}
              {...form.register('logoUrl')}
            />
            <TextField
              label='Portada (URL https, opcional)'
              type='url'
              error={errors.coverUrl?.message}
              {...form.register('coverUrl')}
            />
          </div>
          <TextField
            label='Descripción (opcional)'
            error={errors.description?.message}
            {...form.register('description')}
          />
          <fieldset className='space-y-3'>
            <legend className='mb-2 text-sm font-semibold'>Categorías</legend>
            <div className='flex flex-wrap gap-4'>
              {categories.data?.map((category) => (
                <CheckField
                  key={category.id}
                  checked={categoryIds.includes(category.id)}
                  onChange={(event) =>
                    form.setValue(
                      'categoryIds',
                      event.target.checked
                        ? [...categoryIds, category.id]
                        : categoryIds.filter((id) => id !== category.id),
                      { shouldDirty: true },
                    )
                  }
                >
                  {category.name}
                </CheckField>
              ))}
            </div>
          </fieldset>
        </fieldset>
        <ErrorNotice
          error={cities.error}
          onRetry={() => {
            void cities.refetch()
          }}
        />
        <ErrorNotice
          error={categories.error}
          onRetry={() => {
            void categories.refetch()
          }}
        />
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button type='button' variant='outline' onClick={onClose} disabled={isSubmitting}>
            Cancelar
          </Button>
          <Button type='submit' disabled={isSubmitting}>
            {isSubmitting ? 'Guardando…' : 'Guardar negocio'}
          </Button>
        </div>
      </form>
    </EditorDialog>
  )
}
