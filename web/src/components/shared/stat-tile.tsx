import type { ReactNode } from 'react'
import { cn } from '@/lib/cn'

interface StatTileProps {
  label: string
  value: ReactNode
  /** Contexto bajo la cifra: "+12 % vs. semana anterior". */
  hint?: ReactNode
  className?: string
}

/** Una cifra destacada con su etiqueta. */
export function StatTile({ label, value, hint, className }: StatTileProps) {
  return (
    <div className={cn('bg-card rounded-lg border px-4 py-3', className)}>
      <p className='text-muted-foreground text-xs'>{label}</p>
      <p className='font-display text-2xl font-semibold tabular-nums'>{value}</p>
      {hint && <p className='text-muted-foreground mt-0.5 text-xs'>{hint}</p>}
    </div>
  )
}
