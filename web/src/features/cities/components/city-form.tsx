import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { CheckField, TextField } from '@/components/shared/form-controls'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import type { AdminCity } from '../model/city'
import { saveCityMutation } from '../mutations/cities.mutations'
import { cityPayload, citySchema, type CityForm } from '../schemas/city.schemas'

const soles = (cents: number) => String(cents / 100)

function defaults(city?: AdminCity): CityForm {
  return {
    name: city?.name ?? '',
    region: city?.region ?? '',
    centerLat: city?.centerLat ?? -14.7936,
    centerLng: city?.centerLng ?? -71.4128,
    coverageKm: city?.coverageKm ?? 5,
    maxDeliveryKm: city?.maxDeliveryKm ?? 5,
    baseDeliveryFee: soles(city?.baseDeliveryFee.amount ?? 300),
    feePerKm: soles(city?.feePerKm.amount ?? 100),
    routeFactor: city?.routeFactor ?? 1.3,
    avgSpeedKmh: city?.avgSpeedKmh ?? 20,
    isActive: city?.isActive ?? false,
  }
}

export function CityFormDialog({ city, onClose }: { city?: AdminCity; onClose: () => void }) {
  const form = useForm<CityForm>({
    resolver: zodResolver(citySchema),
    defaultValues: defaults(city),
  })
  const mutation = useMutation(saveCityMutation(city?.id))
  const { errors, isSubmitting } = form.formState
  const submit = form.handleSubmit(async (values) => {
    try {
      await mutation.mutateAsync(cityPayload(values, city?.currency ?? 'PEN'))
      toast.success(city ? 'Ciudad actualizada.' : 'Ciudad creada.')
      onClose()
    } catch {
      /* Error visible debajo del formulario. */
    }
  })
  const number = { valueAsNumber: true } as const
  return (
    <EditorDialog
      title={city ? `Editar ${city.name}` : 'Nueva ciudad'}
      description='Los cambios de tarifa aplican a los pedidos nuevos; los ya creados conservan su precio.'
      onClose={onClose}
      busy={isSubmitting}
    >
      <form onSubmit={submit} noValidate className='space-y-6'>
        <fieldset disabled={isSubmitting} className='space-y-6'>
          <div className='grid gap-4 sm:grid-cols-2'>
            <TextField label='Nombre' error={errors.name?.message} {...form.register('name')} />
            <TextField
              label='Región (opcional)'
              error={errors.region?.message}
              {...form.register('region')}
            />
          </div>
          <fieldset className='space-y-4'>
            <legend className='mb-2 font-semibold'>Zona de reparto</legend>
            <div className='grid gap-4 sm:grid-cols-2'>
              <TextField
                label='Latitud del centro'
                type='number'
                step='0.000001'
                error={errors.centerLat?.message}
                {...form.register('centerLat', number)}
              />
              <TextField
                label='Longitud del centro'
                type='number'
                step='0.000001'
                error={errors.centerLng?.message}
                {...form.register('centerLng', number)}
              />
              <TextField
                label='Radio de la zona (km)'
                type='number'
                step='0.1'
                hint='Las direcciones fuera de este radio no pueden pedir.'
                error={errors.coverageKm?.message}
                {...form.register('coverageKm', number)}
              />
              <TextField
                label='Distancia máxima por calle (km)'
                type='number'
                step='0.1'
                hint='Desde el negocio hasta el cliente.'
                error={errors.maxDeliveryKm?.message}
                {...form.register('maxDeliveryKm', number)}
              />
            </div>
          </fieldset>
          <fieldset className='space-y-4'>
            <legend className='mb-2 font-semibold'>Tarifa y tiempos</legend>
            <div className='grid gap-4 sm:grid-cols-2'>
              <TextField
                label='Tarifa base (S/)'
                inputMode='decimal'
                error={errors.baseDeliveryFee?.message}
                {...form.register('baseDeliveryFee')}
              />
              <TextField
                label='Por cada km (S/)'
                inputMode='decimal'
                hint='Los km por calle se redondean hacia arriba.'
                error={errors.feePerKm?.message}
                {...form.register('feePerKm')}
              />
              <TextField
                label='Factor de ruta'
                type='number'
                step='0.05'
                hint='Cuánto más larga es la calle que la línea recta (1.3 = 30 %).'
                error={errors.routeFactor?.message}
                {...form.register('routeFactor', number)}
              />
              <TextField
                label='Velocidad media (km/h)'
                type='number'
                error={errors.avgSpeedKmh?.message}
                {...form.register('avgSpeedKmh', number)}
              />
            </div>
          </fieldset>
          <CheckField {...form.register('isActive')}>Recibe pedidos</CheckField>
        </fieldset>
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button type='button' variant='outline' disabled={isSubmitting} onClick={onClose}>
            Cancelar
          </Button>
          <Button type='submit' disabled={isSubmitting}>
            {isSubmitting ? 'Guardando…' : 'Guardar ciudad'}
          </Button>
        </div>
      </form>
    </EditorDialog>
  )
}
