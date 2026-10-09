import type { ReactNode } from 'react'
import { cn } from '@/lib/cn'

export function StatusBadge({
  active = false,
  children,
}: {
  active?: boolean
  children: ReactNode
}) {
  return (
    <span
      className={cn(
        'inline-flex rounded-full px-2.5 py-1 text-xs font-semibold',
        active ? 'bg-success-soft text-success' : 'bg-secondary text-muted-foreground',
      )}
    >
      {children}
    </span>
  )
}
