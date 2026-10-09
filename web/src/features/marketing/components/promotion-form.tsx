import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation, useQuery } from '@tanstack/react-query'
import { useForm, useWatch } from 'react-hook-form'
import { toast } from 'sonner'
import { adminStoresQuery, citiesQuery } from '@/app/api/lookups'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { CheckField, SelectField, TextField } from '@/components/shared/form-controls'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { SafeImage } from '@/components/shared/safe-image'
import { Button } from '@/components/ui/button'
import { dateTime } from '@/lib/datetime'
import type { Promotion } from '../model/marketing'
import { savePromotionMutation } from '../mutations/marketing.mutations'
import { couponsQuery } from '../queries/marketing.queries'
import { promotionPayload, promotionSchema, type PromotionForm } from '../schemas/marketing.schemas'

function defaults(promotion: Promotion | undefined, cityId: string): PromotionForm {
  const now = new Date()
  const inTwoWeeks = new Date(now.getTime() + 14 * 24 * 60 * 60_000)
  return {
    cityId: promotion?.cityId ?? cityId,
    storeId: promotion?.storeId ?? '',
    couponId: promotion?.couponId ?? '',
    title: promotion?.title ?? '',
    subtitle: promotion?.subtitle ?? '',
    imageUrl: promotion?.imageUrl ?? '',
    startsAt: dateTime.toInputDateTime(promotion?.startsAt ?? now),
    endsAt: dateTime.toInputDateTime(promotion?.endsAt ?? inTwoWeeks),
    sortOrder: promotion?.sortOrder ?? 0,
    isActive: promotion?.isActive ?? true,
  }
}

export function PromotionFormDialog({
  promotion,
  cityId = '',
  onClose,
}: {
  promotion?: Promotion
  /** Ciudad preseleccionada al crear. */
  cityId?: string
  onClose: () => void
}) {
  const cities = useQuery(citiesQuery)
  const stores = useQuery(adminStoresQuery)
  const coupons = useQuery(couponsQuery)
  const form = useForm<PromotionForm>({
    resolver: zodResolver(promotionSchema),
    defaultValues: defaults(promotion, cityId),
  })
  const [selectedCity, imageUrl] = useWatch({ control: form.control, name: ['cityId', 'imageUrl'] })
  const mutation = useMutation(savePromotionMutation(promotion?.id))
  const { errors, isSubmitting } = form.formState
  const submit = form.handleSubmit(async (values) => {
    try {
      await mutation.mutateAsync(promotionPayload(values))
      toast.success(promotion ? 'Banner actualizado.' : 'Banner creado.')
      onClose()
    } catch {
      /* Error visible debajo del formulario. */
    }
  })
  const storeOptions = (stores.data ?? []).filter((store) => store.cityId === selectedCity)
  const couponOptions = (coupons.data ?? []).filter(
    (coupon) => coupon.isActive && (!coupon.cityId || coupon.cityId === selectedCity),
  )
  return (
    <EditorDialog
      title={promotion ? 'Editar banner' : 'Nuevo banner'}
      description='Aparece en el carrusel del inicio de la app, en la ciudad elegida.'
      onClose={onClose}
      busy={isSubmitting}
    >
      <form onSubmit={submit} noValidate className='space-y-5'>
        <fieldset disabled={isSubmitting} className='space-y-5'>
          <div className='grid gap-4 sm:grid-cols-2'>
            <TextField label='Título' error={errors.title?.message} {...form.register('title')} />
            <TextField
              label='Subtítulo (opcional)'
              error={errors.subtitle?.message}
              {...form.register('subtitle')}
            />
          </div>
          <TextField
            label='Imagen (URL https)'
            hint='Horizontal, al menos 1200 × 520 px.'
            error={errors.imageUrl?.message}
            {...form.register('imageUrl')}
          />
          {/^https:\/\/\S+$/.test(imageUrl) && (
            <SafeImage
              src={imageUrl}
              alt='Vista previa del banner'
              className='corner-exit-m aspect-banner w-full object-cover'
            />
          )}
          <div className='grid gap-4 sm:grid-cols-3'>
            <SelectField label='Ciudad' error={errors.cityId?.message} {...form.register('cityId')}>
              <option value=''>Elige una ciudad</option>
              {cities.data?.map((city) => (
                <option key={city.id} value={city.id}>
                  {city.name}
                </option>
              ))}
            </SelectField>
            <SelectField label='Abre el negocio' {...form.register('storeId')}>
              <option value=''>Ninguno</option>
              {storeOptions.map((store) => (
                <option key={store.id} value={store.id}>
                  {store.name}
                </option>
              ))}
            </SelectField>
            <SelectField label='Muestra el cupón' {...form.register('couponId')}>
              <option value=''>Ninguno</option>
              {couponOptions.map((coupon) => (
                <option key={coupon.id} value={coupon.id}>
                  {coupon.code} · {coupon.label}
                </option>
              ))}
            </SelectField>
          </div>
          <div className='grid gap-4 sm:grid-cols-3'>
            <TextField
              label='Desde'
              type='datetime-local'
              error={errors.startsAt?.message}
              {...form.register('startsAt')}
            />
            <TextField
              label='Hasta'
              type='datetime-local'
              error={errors.endsAt?.message}
              {...form.register('endsAt')}
            />
            <TextField
              label='Orden en el carrusel'
              type='number'
              min='0'
              error={errors.sortOrder?.message}
              {...form.register('sortOrder', { valueAsNumber: true })}
            />
          </div>
          <CheckField {...form.register('isActive')}>Activo</CheckField>
        </fieldset>
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button type='button' variant='outline' disabled={isSubmitting} onClick={onClose}>
            Cancelar
          </Button>
          <Button type='submit' disabled={isSubmitting}>
            {isSubmitting ? 'Guardando…' : 'Guardar banner'}
          </Button>
        </div>
      </form>
    </EditorDialog>
  )
}
