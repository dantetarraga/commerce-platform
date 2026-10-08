import type * as React from 'react'
import { cn } from '@/lib/cn'
import { Label } from './label'

function Field({ className, ...props }: React.ComponentProps<'div'>) {
  return <div data-slot='field' className={cn('grid gap-2', className)} {...props} />
}

function FieldLabel(props: React.ComponentProps<typeof Label>) {
  return <Label data-slot='field-label' {...props} />
}

function FieldDescription({ className, ...props }: React.ComponentProps<'p'>) {
  return (
    <p
      data-slot='field-description'
      className={cn('text-muted-foreground text-sm', className)}
      {...props}
    />
  )
}

function FieldError({ className, children, ...props }: React.ComponentProps<'p'>) {
  if (!children) return null
  return (
    <p
      role='alert'
      data-slot='field-error'
      className={cn('text-destructive text-sm font-medium', className)}
      {...props}
    >
      {children}
    </p>
  )
}

export { Field, FieldLabel, FieldDescription, FieldError }
