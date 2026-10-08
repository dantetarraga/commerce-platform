import { cn } from '@/lib/cn'

export function BrandMark({ className }: { className?: string }) {
  return (
    <span
      aria-hidden
      className={cn(
        'corner-exit-s bg-primary font-display text-primary-foreground flex size-10 items-center justify-center pb-1 text-2xl font-bold',
        className,
      )}
    >
      a
    </span>
  )
}
