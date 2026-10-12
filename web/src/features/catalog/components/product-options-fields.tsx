import { Plus, Trash2 } from 'lucide-react'
import { useFieldArray, type UseFormReturn } from 'react-hook-form'
import { CheckField, TextField } from '@/components/shared/form-controls'
import { Button } from '@/components/ui/button'
import type { ProductForm } from '../schemas/catalog.schemas'

type Form = UseFormReturn<ProductForm>

/** Grupos de opciones: "Cremas" (elige hasta 3), "Bebida" (elige 1, obligatorio). */
export function ProductOptionsFields({ form, disabled }: { form: Form; disabled: boolean }) {
  const { fields, append, remove } = useFieldArray({
    control: form.control,
    name: 'options',
    keyName: 'key',
  })
  return (
    <fieldset disabled={disabled} className='space-y-3'>
      <legend className='font-semibold'>Opciones</legend>
      <p className='text-muted-foreground text-sm'>
        Lo que el cliente elige además: cremas, bebida, término. Con un mínimo de 1, elegir es
        obligatorio.
      </p>
      {fields.map((field, i) => (
        <OptionGroup key={field.key} form={form} index={i} onRemove={() => remove(i)} />
      ))}
      <Button
        type='button'
        variant='outline'
        size='sm'
        onClick={() =>
          append({
            name: '',
            minSelect: 0,
            maxSelect: 1,
            values: [{ name: '', priceDelta: '', isAvailable: true }],
          })
        }
      >
        <Plus aria-hidden />
        Agregar grupo de opciones
      </Button>
    </fieldset>
  )
}

function OptionGroup({
  form,
  index,
  onRemove,
}: {
  form: Form
  index: number
  onRemove: () => void
}) {
  const values = useFieldArray({
    control: form.control,
    name: `options.${index}.values`,
    keyName: 'key',
  })
  const errors = form.formState.errors.options?.[index]
  return (
    <div className='bg-secondary/50 space-y-3 rounded-lg p-4'>
      <div className='grid items-start gap-3 sm:grid-cols-[minmax(0,1fr)_7rem_7rem_auto]'>
        <TextField
          label='Grupo'
          placeholder='Cremas'
          error={errors?.name?.message}
          {...form.register(`options.${index}.name`)}
        />
        <TextField
          label='Elige mínimo'
          type='number'
          min='0'
          error={errors?.minSelect?.message}
          {...form.register(`options.${index}.minSelect`, { valueAsNumber: true })}
        />
        <TextField
          label='Elige máximo'
          type='number'
          min='1'
          error={errors?.maxSelect?.message}
          {...form.register(`options.${index}.maxSelect`, { valueAsNumber: true })}
        />
        <Button
          type='button'
          variant='ghost'
          size='icon'
          className='sm:mt-7'
          aria-label={`Quitar el grupo ${index + 1}`}
          onClick={onRemove}
        >
          <Trash2 aria-hidden />
        </Button>
      </div>
      <ul className='space-y-3' aria-label={`Opciones del grupo ${index + 1}`}>
        {values.fields.map((field, j) => (
          <li
            key={field.key}
            className='grid items-start gap-3 sm:grid-cols-[minmax(0,1fr)_9rem_auto_auto]'
          >
            <TextField
              label={`Opción ${j + 1}`}
              placeholder='Mayonesa'
              error={errors?.values?.[j]?.name?.message}
              {...form.register(`options.${index}.values.${j}.name`)}
            />
            <TextField
              label='Suma (S/)'
              inputMode='decimal'
              placeholder='0'
              error={errors?.values?.[j]?.priceDelta?.message}
              {...form.register(`options.${index}.values.${j}.priceDelta`)}
            />
            <div className='flex h-11 items-center sm:mt-7'>
              <CheckField {...form.register(`options.${index}.values.${j}.isAvailable`)}>
                Disponible
              </CheckField>
            </div>
            <Button
              type='button'
              variant='ghost'
              size='icon'
              className='sm:mt-7'
              aria-label={`Quitar la opción ${j + 1}`}
              disabled={values.fields.length === 1}
              onClick={() => values.remove(j)}
            >
              <Trash2 aria-hidden />
            </Button>
          </li>
        ))}
      </ul>
      {errors?.values?.message && (
        <p className='text-destructive text-sm'>{errors.values.message}</p>
      )}
      <Button
        type='button'
        variant='ghost'
        size='sm'
        onClick={() => values.append({ name: '', priceDelta: '', isAvailable: true })}
      >
        <Plus aria-hidden />
        Agregar opción
      </Button>
    </div>
  )
}
