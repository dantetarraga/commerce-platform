import { zodResolver } from '@hookform/resolvers/zod'
import { LoaderCircle } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { Button } from '@/components/ui/button'
import { Field, FieldError, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { errorMessage } from '@/lib/errors'
import { phoneSchema, type PhoneFormInput, type PhoneFormValues } from '../schemas/auth.schemas'

interface PhoneStepProps {
  onSubmit: (phone: string) => Promise<void>
}

export function PhoneStep({ onSubmit }: PhoneStepProps) {
  const form = useForm<PhoneFormInput, unknown, PhoneFormValues>({
    resolver: zodResolver(phoneSchema),
    defaultValues: { phone: '' },
  })
  const { errors, isSubmitting } = form.formState

  const submit = form.handleSubmit(async ({ phone }) => {
    try {
      await onSubmit(phone)
    } catch (error) {
      form.setError('phone', { message: errorMessage(error) })
    }
  })

  return (
    <form onSubmit={submit} noValidate className='space-y-6'>
      <Field>
        <FieldLabel htmlFor='phone'>Celular</FieldLabel>
        <div className='flex gap-2'>
          <span className='border-input bg-secondary text-muted-foreground flex h-11 items-center rounded-md border px-3 text-sm font-semibold'>
            +51
          </span>
          <Input
            id='phone'
            type='tel'
            inputMode='numeric'
            autoComplete='tel-national'
            placeholder='987 654 321'
            autoFocus
            aria-invalid={errors.phone ? true : undefined}
            aria-describedby='phone-error'
            {...form.register('phone')}
          />
        </div>
        <FieldError id='phone-error'>{errors.phone?.message}</FieldError>
      </Field>
      <Button type='submit' size='lg' className='w-full' disabled={isSubmitting}>
        {isSubmitting && <LoaderCircle className='animate-spin' aria-hidden />}
        Enviar código
      </Button>
    </form>
  )
}
