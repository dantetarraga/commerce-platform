import { useId, type ComponentProps, type ReactNode } from 'react'
import { Field, FieldDescription, FieldError, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'

interface FieldProps {
  label: string
  error?: string
  hint?: ReactNode
}

export function TextField({
  label,
  error,
  hint,
  id: providedId,
  ...props
}: ComponentProps<typeof Input> & FieldProps) {
  const generatedId = useId()
  const id = providedId ?? generatedId
  return (
    <Field>
      <FieldLabel htmlFor={id}>{label}</FieldLabel>
      <Input
        id={id}
        aria-invalid={Boolean(error)}
        aria-describedby={`${id}-help ${id}-error`}
        {...props}
      />
      {hint && <FieldDescription id={`${id}-help`}>{hint}</FieldDescription>}
      <FieldError id={`${id}-error`}>{error}</FieldError>
    </Field>
  )
}

export function SelectField({
  label,
  error,
  hint,
  children,
  ...props
}: ComponentProps<'select'> & FieldProps) {
  const id = useId()
  return (
    <Field>
      <FieldLabel htmlFor={id}>{label}</FieldLabel>
      <select
        id={id}
        className='border-input bg-card focus-visible:ring-ring h-11 w-full min-w-0 rounded-md border px-3 text-sm focus-visible:ring-2'
        aria-invalid={Boolean(error)}
        aria-describedby={`${id}-help ${id}-error`}
        {...props}
      >
        {children}
      </select>
      {hint && <FieldDescription id={`${id}-help`}>{hint}</FieldDescription>}
      <FieldError id={`${id}-error`}>{error}</FieldError>
    </Field>
  )
}

export function CheckField({ children, ...props }: ComponentProps<'input'>) {
  return (
    <label className='flex items-center gap-3 text-sm'>
      <input type='checkbox' className='accent-primary size-4 shrink-0' {...props} />
      {children}
    </label>
  )
}
