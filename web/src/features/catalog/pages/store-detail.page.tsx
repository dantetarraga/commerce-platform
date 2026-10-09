import { Link, useParams } from '@tanstack/react-router'
import { ArrowLeft } from 'lucide-react'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { StoreDetailSkeleton } from '../components/catalog-skeletons'
import { StoreDetail } from '../components/store-detail'

export function StoreDetailPage() {
  const { storeId } = useParams({ from: '/admin/catalog/$storeId' })
  return (
    <div className='space-y-8'>
      <Link
        to='/admin/catalog'
        className='text-muted-foreground hover:text-primary inline-flex items-center gap-2 text-sm'
      >
        <ArrowLeft className='size-4' aria-hidden />
        Volver al catálogo
      </Link>
      {/* El enlace de vuelta queda usable mientras carga o si falla la ficha. */}
      <QueryBoundary fallback={<StoreDetailSkeleton />}>
        <StoreDetail storeId={storeId} />
      </QueryBoundary>
    </div>
  )
}
