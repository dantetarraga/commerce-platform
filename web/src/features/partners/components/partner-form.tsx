import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation, useQuery } from '@tanstack/react-query'
import { useForm, useWatch } from 'react-hook-form'
import { toast } from 'sonner'
import { adminStoresQuery, citiesQuery, type PartnerAccount } from '@/app/api/lookups'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { CheckField, SelectField, TextField } from '@/components/shared/form-controls'
import { ErrorNotice, LoadingState } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import { savePartnerMutation } from '../mutations/partners.mutations'
import { partnerFormSchema, type PartnerForm, type PartnerRole } from '../schemas/partners.schemas'

export function PartnerFormDialog({
  account,
  phone,
  role,
  onClose,
  onSaved,
}: {
  account?: PartnerAccount
  phone: string
  role: PartnerRole
  onClose: () => void
  onSaved: (phone: string) => void
}) {
  const mutation = useMutation(savePartnerMutation())
  const cities = useQuery(citiesQuery)
  const stores = useQuery({ ...adminStoresQuery, enabled: role === 'MERCHANT' })
  const form = useForm<PartnerForm>({
    resolver: zodResolver(partnerFormSchema),
    defaultValues: {
      phone,
      role,
      firstName: account?.firstName ?? '',
      lastName: account?.lastName ?? '',
      storeIds: [],
      cityId: account?.courier?.cityId ?? '',
      vehicleType: account?.courier?.vehicleType ?? 'MOTO',
      vehicleLabel: account?.courier?.vehicleLabel ?? '',
      plate: account?.courier?.plate ?? '',
    },
  })
  const storeIds = useWatch({ control: form.control, name: 'storeIds' })
  const { errors, isSubmitting } = form.formState
  const submit = form.handleSubmit(async (values) => {
    try {
      const result = await mutation.mutateAsync(values)
      toast.success(role === 'MERCHANT' ? 'Socio de negocio guardado.' : 'Repartidor guardado.')
      onSaved(result.user.phone)
    } catch {
      /* El formulario conserva los datos y presenta el error de la API. */
    }
  })
  return (
    <EditorDialog
      title={role === 'MERCHANT' ? 'Socio de negocio' : 'Repartidor'}
      description='Si el celular ya tiene cuenta, se conserva su nombre y se agrega el rol de socio.'
      busy={isSubmitting}
      onClose={onClose}
    >
      <form onSubmit={submit} noValidate className='space-y-5'>
        <fieldset disabled={isSubmitting} className='grid gap-4 sm:grid-cols-2'>
          <TextField
            label='Celular'
            type='tel'
            autoComplete='tel-national'
            readOnly={Boolean(account)}
            error={errors.phone?.message}
            {...form.register('phone')}
          />
          <div className='text-muted-foreground self-center text-sm'>Celular peruano, sin +51.</div>
          <TextField
            label='Nombre'
            autoComplete='given-name'
            readOnly={Boolean(account)}
            error={errors.firstName?.message}
            {...form.register('firstName')}
          />
          <TextField
            label='Apellido'
            autoComplete='family-name'
            readOnly={Boolean(account)}
            error={errors.lastName?.message}
            {...form.register('lastName')}
          />
          {role === 'COURIER' && (
            <>
              <SelectField
                label='Ciudad'
                error={errors.cityId?.message}
                {...form.register('cityId')}
              >
                <option value=''>Elige una ciudad</option>
                {cities.data?.map((city) => (
                  <option key={city.id} value={city.id}>
                    {city.name}
                  </option>
                ))}
              </SelectField>
              <SelectField label='Tipo de vehículo' {...form.register('vehicleType')}>
                <option value='MOTO'>Moto</option>
                <option value='BICI'>Bicicleta</option>
                <option value='AUTO'>Auto</option>
              </SelectField>
              <TextField
                label='Descripción del vehículo'
                placeholder='Moto roja'
                error={errors.vehicleLabel?.message}
                {...form.register('vehicleLabel')}
              />
              <TextField
                label='Placa (opcional)'
                error={errors.plate?.message}
                {...form.register('plate')}
              />
            </>
          )}
          {role === 'MERCHANT' && (
            <fieldset className='space-y-3 sm:col-span-2'>
              <legend className='mb-2 text-sm font-semibold'>Asignar negocios (opcional)</legend>
              <p className='text-muted-foreground text-sm'>
                Puedes crear el socio ahora y registrar su negocio desde Catálogo después.
              </p>
              {stores.isPending && <LoadingState />}
              <ErrorNotice
                error={stores.error}
                onRetry={() => {
                  void stores.refetch()
                }}
              />
              <div className='max-h-48 space-y-3 overflow-y-auto'>
                {stores.data
                  ?.filter((store) => store.ownerId !== account?.id)
                  .map((store) => (
                    <CheckField
                      key={store.id}
                      checked={storeIds.includes(store.id)}
                      onChange={(event) =>
                        form.setValue(
                          'storeIds',
                          event.target.checked
                            ? [...storeIds, store.id]
                            : storeIds.filter((id) => id !== store.id),
                          { shouldDirty: true },
                        )
                      }
                    >
                      {store.name}
                    </CheckField>
                  ))}
              </div>
              {storeIds.length > 0 && (
                <p className='bg-primary-soft text-primary rounded-lg p-3 text-sm'>
                  Al guardar, los negocios seleccionados pasarán a este socio. Su dueño anterior
                  perderá el acceso a ellos.
                </p>
              )}
            </fieldset>
          )}
        </fieldset>
        {role === 'COURIER' && (
          <ErrorNotice
            error={cities.error}
            onRetry={() => {
              void cities.refetch()
            }}
          />
        )}
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button type='button' variant='outline' disabled={isSubmitting} onClick={onClose}>
            Cancelar
          </Button>
          <Button type='submit' disabled={isSubmitting}>
            {isSubmitting ? 'Guardando…' : 'Guardar socio'}
          </Button>
        </div>
      </form>
    </EditorDialog>
  )
}
