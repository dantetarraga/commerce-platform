import { Skeleton } from '@/components/ui/skeleton'

export function CouponsSkeleton() {
  return (
    <ul role='status' aria-label='Cargando cupones' className='divide-y'>
      {[0, 1, 2].map((index) => (
        <li key={index} className='flex items-center justify-between gap-4 py-4'>
          <div className='space-y-2'>
            <Skeleton className='h-6 w-56' />
            <Skeleton className='h-4 w-40' />
          </div>
          <Skeleton className='h-9 w-32' />
        </li>
      ))}
    </ul>
  )
}

export function PromotionsSkeleton() {
  return (
    <div
      role='status'
      aria-label='Cargando banners'
      className='grid gap-4 sm:grid-cols-2 xl:grid-cols-3'
    >
      {[0, 1, 2].map((index) => (
        <div key={index} className='corner-exit-m bg-card overflow-hidden border'>
          <Skeleton className='aspect-banner w-full rounded-none' />
          <div className='space-y-2 p-4'>
            <Skeleton className='h-5 w-40' />
            <Skeleton className='h-4 w-28' />
          </div>
        </div>
      ))}
    </div>
  )
}
