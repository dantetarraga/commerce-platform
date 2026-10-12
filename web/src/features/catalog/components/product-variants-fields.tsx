import { Plus, Trash2 } from 'lucide-react'
import { useFieldArray, type UseFormReturn } from 'react-hook-form'
import { CheckField, TextField } from '@/components/shared/form-controls'
import { Button } from '@/components/ui/button'
import type { ProductForm } from '../schemas/catalog.schemas'

type Form = UseFormReturn<ProductForm>

/** Tamaños o presentaciones ("1/4", "1/2", "Entero"): cada una con su precio. */
export function ProductVariantsFields({ form, disabled }: { form: Form; disabled: boolean }) {
  const { fields, append, remove } = useFieldArray({
    control: form.control,
    name: 'variants',
    keyName: 'key',
  })
  const errors = form.formState.errors.variants
  return (
    <fieldset disabled={disabled} className='space-y-3'>
      <legend className='font-semibold'>Variantes</legend>
      <p className='text-muted-foreground text-sm'>
        Tamaños o presentaciones con precio propio, como «1/4» y «1/2». Con variantes, el cliente
        elige una y paga su precio.
      </p>
      {fields.map((field, i) => (
        <div
          key={field.key}
          className='grid items-start gap-3 sm:grid-cols-[minmax(0,1fr)_9rem_auto_auto]'
        >
          <TextField
            label={`Variante ${i + 1}`}
            placeholder='1/4 de pollo'
            error={errors?.[i]?.name?.message}
            {...form.register(`variants.${i}.name`)}
          />
          <TextField
            label='Precio (S/)'
            inputMode='decimal'
            error={errors?.[i]?.price?.message}
            {...form.register(`variants.${i}.price`)}
          />
          <div className='flex h-11 items-center sm:mt-7'>
            <CheckField {...form.register(`variants.${i}.isAvailable`)}>Disponible</CheckField>
          </div>
          <Button
            type='button'
            variant='ghost'
            size='icon'
            className='sm:mt-7'
            aria-label={`Quitar la variante ${i + 1}`}
            onClick={() => remove(i)}
          >
            <Trash2 aria-hidden />
          </Button>
        </div>
      ))}
      <Button
        type='button'
        variant='outline'
        size='sm'
        onClick={() => append({ name: '', price: '', isAvailable: true })}
      >
        <Plus aria-hidden />
        Agregar variante
      </Button>
    </fieldset>
  )
}
