import { Skeleton } from '@/components/ui/skeleton'

export function CitiesSkeleton() {
  return (
    <div role='status' aria-label='Cargando ciudades' className='space-y-5'>
      {[0, 1].map((index) => (
        <div key={index} className='corner-exit-m bg-card space-y-5 border p-5 md:p-6'>
          <div className='space-y-2'>
            <Skeleton className='h-6 w-40' />
            <Skeleton className='h-4 w-56' />
          </div>
          <div className='grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6'>
            {[0, 1, 2, 3, 4, 5].map((fact) => (
              <Skeleton key={fact} className='h-10 w-full' />
            ))}
          </div>
          <Skeleton className='h-16 w-full' />
        </div>
      ))}
    </div>
  )
}
