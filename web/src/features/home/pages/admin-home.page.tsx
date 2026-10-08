import { ClipboardList } from 'lucide-react'
import { EmptyState } from '@/components/shared/empty-state'
import { PageHeader } from '@/components/shared/page-header'

const NEXT_MODULES = [
  { title: 'Socios', detail: 'Alta y suspensión de negocios y repartidores, sin Swagger.' },
  { title: 'Catálogo', detail: 'Negocios, horarios, productos con variantes y fotos.' },
  { title: 'Marketing', detail: 'Cupones y banners del inicio.' },
  { title: 'Pedidos en vivo', detail: 'Tablero por ciudad con alertas de pedidos sin respuesta.' },
]

export function AdminHomePage() {
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Inicio'
        description='La operación de Apamuy en un solo lugar.'
      />
      <EmptyState
        icon={ClipboardList}
        title='El panel está en construcción'
        description='Mientras tanto, la operación sigue en la app Apamuy Socios y en Swagger. Estos módulos llegan primero:'
      />
      <ul className='grid gap-4 sm:grid-cols-2'>
        {NEXT_MODULES.map((module) => (
          <li key={module.title} className='corner-exit-m bg-card border p-5'>
            <p className='font-display text-lg font-semibold'>{module.title}</p>
            <p className='text-muted-foreground text-sm'>{module.detail}</p>
          </li>
        ))}
      </ul>
    </div>
  )
}
