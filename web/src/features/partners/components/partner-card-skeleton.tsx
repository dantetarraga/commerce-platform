import { Skeleton } from '@/components/ui/skeleton'

/** Fallback mientras se busca un socio: la forma de su ficha. */
export function PartnerCardSkeleton() {
  return (
    <div
      role='status'
      aria-label='Buscando cuenta'
      className='corner-exit-m bg-card space-y-5 border p-5 md:p-6'
    >
      <div className='flex items-center gap-4'>
        <Skeleton className='size-12 rounded-full' />
        <div className='space-y-2'>
          <Skeleton className='h-5 w-44' />
          <Skeleton className='h-4 w-28' />
        </div>
      </div>
      <div className='flex gap-2'>
        <Skeleton className='h-6 w-20' />
        <Skeleton className='h-6 w-24' />
      </div>
      <Skeleton className='h-16 w-full' />
    </div>
  )
}
