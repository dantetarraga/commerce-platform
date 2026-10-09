import { Link } from '@tanstack/react-router'
import { ChartColumn, Store, UtensilsCrossed } from 'lucide-react'
import { PageHeader } from '@/components/shared/page-header'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { Button } from '@/components/ui/button'
import { DashboardSkeleton } from '../components/partner-skeletons'
import { TodaySummary } from '../components/today-summary'

export function PartnerHomePage() {
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Portal Socios'
        title='Hoy en tu negocio'
        description='Los pedidos se atienden desde la app Apamuy Socios; aquí ves cómo va el día.'
        actions={
          <>
            <Button asChild variant='outline'>
              <Link to='/partner/menu'>
                <UtensilsCrossed aria-hidden />
                Menú
              </Link>
            </Button>
            <Button asChild variant='outline'>
              <Link to='/partner/store'>
                <Store aria-hidden />
                Mi tienda
              </Link>
            </Button>
            <Button asChild>
              <Link to='/partner/reports'>
                <ChartColumn aria-hidden />
                Reportes
              </Link>
            </Button>
          </>
        }
      />
      <QueryBoundary fallback={<DashboardSkeleton />}>
        <TodaySummary />
      </QueryBoundary>
    </div>
  )
}
