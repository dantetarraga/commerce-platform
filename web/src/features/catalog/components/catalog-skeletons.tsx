import { Skeleton } from '@/components/ui/skeleton'

/** Fallback de la lista de negocios: filtros y filas con la forma real. */
export function StoresDirectorySkeleton() {
  return (
    <div role='status' aria-label='Cargando negocios' className='space-y-6'>
      <div className='grid gap-4 md:grid-cols-3'>
        {[0, 1, 2].map((index) => (
          <div key={index} className='space-y-2'>
            <Skeleton className='h-4 w-28' />
            <Skeleton className='h-11 w-full' />
          </div>
        ))}
      </div>
      <ul className='divide-y'>
        {[0, 1, 2, 3].map((index) => (
          <li key={index} className='flex items-center justify-between gap-4 py-4'>
            <div className='space-y-2'>
              <Skeleton className='h-5 w-48' />
              <Skeleton className='h-4 w-32' />
            </div>
            <Skeleton className='h-9 w-24' />
          </li>
        ))}
      </ul>
    </div>
  )
}

/** Fallback de la ficha de un negocio. */
export function StoreDetailSkeleton() {
  return (
    <div role='status' aria-label='Cargando negocio' className='space-y-8'>
      <div className='space-y-3'>
        <Skeleton className='h-4 w-20' />
        <Skeleton className='h-9 w-72 max-w-full' />
        <Skeleton className='h-4 w-56 max-w-full' />
      </div>
      <div className='grid gap-5 lg:grid-cols-2'>
        {[0, 1].map((index) => (
          <div key={index} className='corner-exit-m bg-card space-y-3 border p-5'>
            <Skeleton className='h-6 w-40' />
            <Skeleton className='h-4 w-full' />
            <Skeleton className='h-4 w-3/4' />
          </div>
        ))}
      </div>
      <div className='corner-exit-m bg-card space-y-4 border p-5'>
        <Skeleton className='h-6 w-32' />
        {[0, 1, 2].map((index) => (
          <Skeleton key={index} className='h-14 w-full' />
        ))}
      </div>
    </div>
  )
}

/** Fallback de las categorías. */
export function CategoriesSkeleton() {
  return (
    <div
      role='status'
      aria-label='Cargando categorías'
      className='grid gap-3 sm:grid-cols-2 lg:grid-cols-3'
    >
      {[0, 1, 2].map((index) => (
        <Skeleton key={index} className='h-12 w-full' />
      ))}
    </div>
  )
}
