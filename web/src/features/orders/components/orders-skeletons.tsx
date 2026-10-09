import { Skeleton } from '@/components/ui/skeleton'

export function LiveBoardSkeleton() {
  return (
    <div role='status' aria-label='Cargando pedidos en curso' className='space-y-6'>
      <div className='grid grid-cols-2 gap-3 md:grid-cols-4'>
        {[0, 1, 2, 3].map((index) => (
          <Skeleton key={index} className='h-16 w-full' />
        ))}
      </div>
      <div className='grid gap-4 md:grid-cols-2 xl:grid-cols-4'>
        {[0, 1, 2, 3].map((column) => (
          <div key={column} className='bg-secondary/50 space-y-3 rounded-xl p-3'>
            <Skeleton className='h-5 w-28' />
            {[0, 1].map((card) => (
              <Skeleton key={card} className='h-28 w-full' />
            ))}
          </div>
        ))}
      </div>
    </div>
  )
}

export function OrdersHistorySkeleton() {
  return (
    <ul role='status' aria-label='Cargando pedidos' className='divide-y'>
      {[0, 1, 2, 3, 4].map((index) => (
        <li key={index} className='flex items-center justify-between gap-4 py-3'>
          <div className='space-y-2'>
            <Skeleton className='h-4 w-48' />
            <Skeleton className='h-4 w-32' />
          </div>
          <Skeleton className='h-6 w-24' />
        </li>
      ))}
    </ul>
  )
}
