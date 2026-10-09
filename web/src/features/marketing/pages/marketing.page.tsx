import { useSuspenseQuery } from '@tanstack/react-query'
import { useState, useTransition } from 'react'
import { citiesQuery } from '@/app/api/lookups'
import { SelectField } from '@/components/shared/form-controls'
import { PageHeader } from '@/components/shared/page-header'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { CouponFormDialog } from '../components/coupon-form'
import { CouponsTable } from '../components/coupons-table'
import { CouponsSkeleton, PromotionsSkeleton } from '../components/marketing-skeletons'
import { PromotionFormDialog } from '../components/promotion-form'
import { PromotionsBoard } from '../components/promotions-board'
import type { Coupon, Promotion } from '../model/marketing'

type Editor =
  | { kind: 'coupon'; coupon?: Coupon }
  | { kind: 'promotion'; promotion?: Promotion; cityId?: string }

export function MarketingPage() {
  const [editor, setEditor] = useState<Editor | null>(null)
  const handleClose = () => setEditor(null)
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Marketing'
        description='Cupones de descuento y banners del inicio de la app.'
        actions={<Button onClick={() => setEditor({ kind: 'coupon' })}>Nuevo cupón</Button>}
      />
      <section className='corner-exit-m bg-card space-y-4 border p-5 md:p-6'>
        <h2 className='text-xl font-semibold'>Cupones</h2>
        <QueryBoundary fallback={<CouponsSkeleton />}>
          <CouponsTable onEdit={(coupon) => setEditor({ kind: 'coupon', coupon })} />
        </QueryBoundary>
      </section>
      <section className='corner-exit-m bg-card space-y-4 border p-5 md:p-6'>
        <QueryBoundary fallback={<Skeleton className='h-11 w-full max-w-xs' />}>
          <PromotionsSection
            onCreate={(cityId) => setEditor({ kind: 'promotion', cityId })}
            onEdit={(promotion) => setEditor({ kind: 'promotion', promotion })}
          />
        </QueryBoundary>
      </section>
      {editor?.kind === 'coupon' && (
        <CouponFormDialog coupon={editor.coupon} onClose={handleClose} />
      )}
      {editor?.kind === 'promotion' && (
        <PromotionFormDialog
          promotion={editor.promotion}
          cityId={editor.cityId}
          onClose={handleClose}
        />
      )}
    </div>
  )
}

interface PromotionsSectionProps {
  onCreate: (cityId: string) => void
  onEdit: (promotion: Promotion) => void
}

function PromotionsSection({ onCreate, onEdit }: PromotionsSectionProps) {
  const { data: cities } = useSuspenseQuery(citiesQuery)
  const [cityId, setCityId] = useState(cities.length === 1 ? cities[0].id : '')
  const [isSwitching, startSwitch] = useTransition()
  return (
    <>
      <div className='flex flex-wrap items-end justify-between gap-4'>
        <div className='space-y-1'>
          <h2 className='text-xl font-semibold'>Banners del inicio</h2>
          <p className='text-muted-foreground text-sm'>Se muestran por ciudad, en orden.</p>
        </div>
        <div className='flex flex-wrap items-end gap-3'>
          <div className='w-56'>
            <SelectField
              label='Ciudad'
              value={cityId}
              // Al cambiar de ciudad se quedan los banners anteriores hasta tener los nuevos.
              onChange={(event) => {
                const next = event.target.value
                startSwitch(() => setCityId(next))
              }}
            >
              <option value=''>Todas</option>
              {cities.map((city) => (
                <option key={city.id} value={city.id}>
                  {city.name}
                </option>
              ))}
            </SelectField>
          </div>
          <Button variant='outline' onClick={() => onCreate(cityId)}>
            Nuevo banner
          </Button>
        </div>
      </div>
      <div className={isSwitching ? 'opacity-60 transition-opacity' : undefined}>
        <QueryBoundary fallback={<PromotionsSkeleton />}>
          <PromotionsBoard cityId={cityId} onEdit={onEdit} />
        </QueryBoundary>
      </div>
    </>
  )
}
