import { Store } from 'lucide-react'
import { EmptyState } from '@/components/shared/empty-state'
import { PageHeader } from '@/components/shared/page-header'

export function MerchantHomePage() {
  return (
    <div className='space-y-8'>
      <PageHeader eyebrow='Portal Socios' title='Inicio' description='Tu negocio en Apamuy.' />
      <EmptyState
        icon={Store}
        title='Muy pronto: tu menú, horarios y reportes'
        description='Por ahora, los pedidos se atienden desde la app Apamuy Socios. Aquí vas a poder editar tu menú con fotos, cambiar horarios y ver tus ventas.'
      />
    </div>
  )
}
