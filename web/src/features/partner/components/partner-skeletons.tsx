import { Skeleton } from '@/components/ui/skeleton'

/** Cifras arriba y un bloque de gráfico: la forma de inicio, reportes y rendición. */
export function DashboardSkeleton() {
  return (
    <div role='status' aria-label='Cargando cifras' className='space-y-6'>
      <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
        {[0, 1, 2, 3].map((index) => (
          <Skeleton key={index} className='h-20 w-full' />
        ))}
      </div>
      <Skeleton className='h-64 w-full' />
    </div>
  )
}
