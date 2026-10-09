import { PageHeader } from '@/components/shared/page-header'
import { PartnerStorePicker } from '@/components/shared/partner-store-picker'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { StoreDetailSkeleton } from '../components/catalog-skeletons'
import { PartnerCatalog } from '../components/partner-catalog'
import { StoreProductsCard } from '../components/store-products-card'
import { StoreSectionsCard } from '../components/store-sections-card'
import { CatalogScopeContext } from '../model/catalog-scope'

export function PartnerMenuPage() {
  return (
    <CatalogScopeContext value='merchant'>
      <div className='space-y-8'>
        <PageHeader
          eyebrow='Portal Socios'
          title='Menú'
          description='Secciones, productos, precios y disponibilidad. Los cambios se ven al instante en la app.'
          actions={
            <QueryBoundary fallback={null}>
              <PartnerStorePicker />
            </QueryBoundary>
          }
        />
        <QueryBoundary fallback={<StoreDetailSkeleton />}>
          <PartnerCatalog>
            {(store) => (
              <div className='space-y-6'>
                <StoreSectionsCard store={store} />
                <StoreProductsCard store={store} />
              </div>
            )}
          </PartnerCatalog>
        </QueryBoundary>
      </div>
    </CatalogScopeContext>
  )
}
