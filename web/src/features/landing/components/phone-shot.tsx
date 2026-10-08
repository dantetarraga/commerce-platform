import { cn } from '@/lib/cn'

/** Captura real de la app dentro de un marco de teléfono. */
export function PhoneShot({
  src,
  alt,
  className,
}: {
  src: string
  alt: string
  className?: string
}) {
  return (
    <div
      className={cn(
        'bg-foreground ring-foreground/5 w-56 rounded-[2.25rem] p-2 shadow-2xl ring-1 sm:w-64',
        className,
      )}
    >
      <img
        src={src}
        alt={alt}
        width={390}
        height={844}
        loading='lazy'
        decoding='async'
        className='bg-background block h-auto w-full rounded-[1.75rem]'
      />
    </div>
  )
}
