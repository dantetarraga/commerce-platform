import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation, useQuery } from '@tanstack/react-query'
import { useForm, useWatch } from 'react-hook-form'
import { toast } from 'sonner'
import { adminStoresQuery, citiesQuery } from '@/app/api/lookups'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { CheckField, SelectField, TextField } from '@/components/shared/form-controls'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import { dateTime } from '@/lib/datetime'
import type { Coupon } from '../model/marketing'
import { saveCouponMutation } from '../mutations/marketing.mutations'
import { couponPayload, couponSchema, type CouponForm } from '../schemas/marketing.schemas'

const soles = (money: { amount: number } | null) => (money ? String(money.amount / 100) : '')

function defaults(coupon?: Coupon): CouponForm {
  const now = new Date()
  const inAMonth = new Date(now.getTime() + 30 * 24 * 60 * 60_000)
  return {
    code: coupon?.code ?? '',
    label: coupon?.label ?? '',
    description: coupon?.description ?? '',
    type: coupon?.type ?? 'PERCENTAGE',
    percentOff: coupon?.percentOff == null ? '' : String(coupon.percentOff),
    amountOff: soles(coupon?.amountOff ?? null),
    maxDiscount: soles(coupon?.maxDiscount ?? null),
    minOrderAmount: coupon ? soles(coupon.minOrderAmount) : '0',
    cityId: coupon?.cityId ?? '',
    storeId: coupon?.storeId ?? '',
    startsAt: dateTime.toInputDateTime(coupon?.startsAt ?? now),
    endsAt: dateTime.toInputDateTime(coupon?.endsAt ?? inAMonth),
    usageLimit: coupon?.usageLimit == null ? '' : String(coupon.usageLimit),
    perUserLimit: coupon?.perUserLimit ?? 1,
    firstOrderOnly: coupon?.firstOrderOnly ?? false,
    isActive: coupon?.isActive ?? true,
  }
}

export function CouponFormDialog({ coupon, onClose }: { coupon?: Coupon; onClose: () => void }) {
  const cities = useQuery(citiesQuery)
  const stores = useQuery(adminStoresQuery)
  const form = useForm<CouponForm>({
    resolver: zodResolver(couponSchema),
    defaultValues: defaults(coupon),
  })
  const [type, cityId] = useWatch({ control: form.control, name: ['type', 'cityId'] })
  const mutation = useMutation(saveCouponMutation(coupon?.id))
  const { errors, isSubmitting } = form.formState
  const submit = form.handleSubmit(async (values) => {
    try {
      await mutation.mutateAsync(couponPayload(values))
      toast.success(coupon ? 'Cupón actualizado.' : 'Cupón creado.')
      onClose()
    } catch {
      /* Error visible debajo del formulario. */
    }
  })
  const storeOptions = (stores.data ?? []).filter((store) => !cityId || store.cityId === cityId)
  return (
    <EditorDialog
      title={coupon ? `Editar cupón ${coupon.code}` : 'Nuevo cupón'}
      description='Los clientes lo escriben al pagar. El descuento lo calcula el backend.'
      onClose={onClose}
      busy={isSubmitting}
    >
      <form onSubmit={submit} noValidate className='space-y-5'>
        <fieldset disabled={isSubmitting} className='space-y-5'>
          <div className='grid gap-4 sm:grid-cols-2'>
            <TextField
              label='Código'
              autoCapitalize='characters'
              readOnly={Boolean(coupon)}
              hint={coupon ? 'El código no se cambia.' : 'Letras y números, sin espacios.'}
              error={errors.code?.message}
              {...form.register('code')}
            />
            <TextField
              label='Lo que ve el cliente'
              placeholder='S/ 5 de bienvenida'
              error={errors.label?.message}
              {...form.register('label')}
            />
          </div>
          <TextField
            label='Descripción (opcional)'
            error={errors.description?.message}
            {...form.register('description')}
          />
          <div className='grid gap-4 sm:grid-cols-3'>
            <SelectField label='Tipo de descuento' {...form.register('type')}>
              <option value='PERCENTAGE'>Porcentaje</option>
              <option value='FIXED_AMOUNT'>Monto fijo</option>
              <option value='FREE_DELIVERY'>Envío gratis</option>
            </SelectField>
            {type === 'PERCENTAGE' && (
              <>
                <TextField
                  label='Porcentaje'
                  inputMode='numeric'
                  placeholder='10'
                  error={errors.percentOff?.message}
                  {...form.register('percentOff')}
                />
                <TextField
                  label='Tope (S/, opcional)'
                  inputMode='decimal'
                  error={errors.maxDiscount?.message}
                  {...form.register('maxDiscount')}
                />
              </>
            )}
            {type === 'FIXED_AMOUNT' && (
              <TextField
                label='Descuento (S/)'
                inputMode='decimal'
                error={errors.amountOff?.message}
                {...form.register('amountOff')}
              />
            )}
          </div>
          <div className='grid gap-4 sm:grid-cols-3'>
            <TextField
              label='Pedido mínimo (S/)'
              inputMode='decimal'
              error={errors.minOrderAmount?.message}
              {...form.register('minOrderAmount')}
            />
            <SelectField label='Ciudad' {...form.register('cityId')}>
              <option value=''>Todas las ciudades</option>
              {cities.data?.map((city) => (
                <option key={city.id} value={city.id}>
                  {city.name}
                </option>
              ))}
            </SelectField>
            <SelectField label='Negocio' {...form.register('storeId')}>
              <option value=''>Todos los negocios</option>
              {storeOptions.map((store) => (
                <option key={store.id} value={store.id}>
                  {store.name}
                </option>
              ))}
            </SelectField>
          </div>
          <div className='grid gap-4 sm:grid-cols-2'>
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
          </div>
          <div className='grid gap-4 sm:grid-cols-2'>
            <TextField
              label='Usos en total (opcional)'
              inputMode='numeric'
              hint='Vacío: sin límite.'
              error={errors.usageLimit?.message}
              {...form.register('usageLimit')}
            />
            <TextField
              label='Usos por cliente'
              type='number'
              min='1'
              error={errors.perUserLimit?.message}
              {...form.register('perUserLimit', { valueAsNumber: true })}
            />
          </div>
          <div className='space-y-3'>
            <CheckField {...form.register('firstOrderOnly')}>Solo para el primer pedido</CheckField>
            <CheckField {...form.register('isActive')}>Activo</CheckField>
          </div>
        </fieldset>
        <ErrorNotice error={mutation.error} />
        <div className='flex justify-end gap-3'>
          <Button type='button' variant='outline' disabled={isSubmitting} onClick={onClose}>
            Cancelar
          </Button>
          <Button type='submit' disabled={isSubmitting}>
            {isSubmitting ? 'Guardando…' : 'Guardar cupón'}
          </Button>
        </div>
      </form>
    </EditorDialog>
  )
}
