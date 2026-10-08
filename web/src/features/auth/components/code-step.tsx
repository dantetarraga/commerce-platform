import { zodResolver } from '@hookform/resolvers/zod'
import { ArrowLeft, LoaderCircle } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { Button } from '@/components/ui/button'
import { Field, FieldDescription, FieldError, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { errorMessage } from '@/lib/errors'
import { codeSchema, type CodeFormValues } from '../schemas/auth.schemas'

interface CodeStepProps {
  phone: string
  resendIn: number
  isResending: boolean
  onSubmit: (code: string) => Promise<void>
  onResend: () => void
  onBack: () => void
}

const formatPhone = (phone: string) => phone.replace(/^(\d{3})(\d{3})(\d{3})$/, '$1 $2 $3')

export function CodeStep({
  phone,
  resendIn,
  isResending,
  onSubmit,
  onResend,
  onBack,
}: CodeStepProps) {
  const form = useForm<CodeFormValues>({
    resolver: zodResolver(codeSchema),
    defaultValues: { code: '' },
  })
  const { errors, isSubmitting } = form.formState

  const submit = form.handleSubmit(async ({ code }) => {
    try {
      await onSubmit(code)
    } catch (error) {
      form.setError('code', { message: errorMessage(error) })
    }
  })

  return (
    <form onSubmit={submit} noValidate className='space-y-6'>
      <Field>
        <FieldLabel htmlFor='code'>Código de 6 dígitos</FieldLabel>
        <FieldDescription>
          Lo enviamos por SMS al{' '}
          <span className='text-foreground font-semibold'>{formatPhone(phone)}</span>.
        </FieldDescription>
        <Input
          id='code'
          inputMode='numeric'
          autoComplete='one-time-code'
          maxLength={6}
          placeholder='••••••'
          autoFocus
          className='font-display h-14 text-center text-2xl tracking-[0.5em]'
          aria-invalid={errors.code ? true : undefined}
          aria-describedby='code-error'
          {...form.register('code')}
        />
        <FieldError id='code-error'>{errors.code?.message}</FieldError>
      </Field>
      <Button type='submit' size='lg' className='w-full' disabled={isSubmitting}>
        {isSubmitting && <LoaderCircle className='animate-spin' aria-hidden />}
        Ingresar
      </Button>
      <div className='flex items-center justify-between'>
        <Button type='button' variant='ghost' size='sm' onClick={onBack}>
          <ArrowLeft aria-hidden />
          Cambiar número
        </Button>
        <Button
          type='button'
          variant='link'
          size='sm'
          disabled={resendIn > 0 || isResending}
          onClick={onResend}
        >
          {resendIn > 0 ? `Reenviar en ${resendIn} s` : 'Reenviar código'}
        </Button>
      </div>
    </form>
  )
}
