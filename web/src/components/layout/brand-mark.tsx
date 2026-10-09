import { cn } from '@/lib/cn'

/** La "A" del logo en su baldosa, como el ícono de la app. */
export function BrandMark({ className }: { className?: string }) {
  return (
    <span
      aria-hidden
      className={cn(
        'corner-exit-s bg-primary font-brand brand-shadow-sm text-ink-foreground flex size-10 items-center justify-center text-2xl',
        className,
      )}
    >
      A
    </span>
  )
}

/** "APAMUY" con letra de afiche chicha. */
export function BrandLogo({ className }: { className?: string }) {
  return (
    <span
      className={cn(
        'font-brand text-primary brand-shadow-sm text-2xl leading-none whitespace-nowrap',
        className,
      )}
    >
      APAMUY
    </span>
  )
}
