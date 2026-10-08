import type { ReactNode } from 'react'

export function PageHeader({
  eyebrow,
  title,
  description,
  actions,
}: {
  eyebrow?: string
  title: string
  description?: ReactNode
  actions?: ReactNode
}) {
  return (
    <header className='flex flex-wrap items-end justify-between gap-4'>
      <div className='space-y-1'>
        {eyebrow && (
          <p className='text-primary text-xs font-bold tracking-widest uppercase'>{eyebrow}</p>
        )}
        <h1 className='text-3xl font-semibold md:text-4xl'>{title}</h1>
        {description && <p className='text-muted-foreground'>{description}</p>}
      </div>
      {actions && <div className='flex gap-2'>{actions}</div>}
    </header>
  )
}
