import type { LucideIcon } from 'lucide-react'
import type { ReactNode } from 'react'
import { cn } from '@/lib/cn'

interface EmptyStateProps {
  icon: LucideIcon
  title: string
  description: ReactNode
  action?: ReactNode
  className?: string
}

export function EmptyState({ icon: Icon, title, description, action, className }: EmptyStateProps) {
  return (
    <div
      className={cn(
        'corner-exit-l bg-card flex flex-col items-start gap-4 border border-dashed p-8',
        className,
      )}
    >
      <div className='corner-exit-s bg-primary-soft text-primary flex size-12 items-center justify-center'>
        <Icon className='size-6' aria-hidden />
      </div>
      <div className='max-w-prose space-y-1'>
        <h2 className='text-xl font-semibold'>{title}</h2>
        <p className='text-muted-foreground'>{description}</p>
      </div>
      {action}
    </div>
  )
}
