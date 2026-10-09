import { Link } from '@tanstack/react-router'
import { ArrowUpRight, Users, UtensilsCrossed } from 'lucide-react'
import { PageHeader } from '@/components/shared/page-header'

const MODULES = [
  {
    title: 'Socios',
    detail: 'Da de alta negocios y repartidores, asigna tiendas y administra sus accesos.',
    to: '/admin/partners',
    icon: Users,
  },
  {
    title: 'Catálogo',
    detail: 'Publica negocios, organiza sus cartas y actualiza productos y horarios.',
    to: '/admin/catalog',
    icon: UtensilsCrossed,
  },
] as const

export function AdminHomePage() {
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Inicio'
        description='La operación de Apamuy en un solo lugar.'
      />
      <div className='grid gap-5 md:grid-cols-2'>
        {MODULES.map(({ title, detail, to, icon: Icon }) => (
          <Link
            key={to}
            to={to}
            className='corner-exit-m bg-card hover:border-primary focus-visible:ring-ring group space-y-5 border p-6 transition-colors focus-visible:ring-2'
          >
            <div className='flex justify-between'>
              <span className='corner-exit-s bg-primary-soft text-primary inline-flex size-12 items-center justify-center'>
                <Icon aria-hidden />
              </span>
              <ArrowUpRight
                className='text-muted-foreground group-hover:text-primary size-5'
                aria-hidden
              />
            </div>
            <div>
              <h2 className='text-2xl font-semibold'>{title}</h2>
              <p className='text-muted-foreground mt-2 text-sm'>{detail}</p>
            </div>
            <p className='text-primary text-sm font-semibold'>
              Abrir {title.toLocaleLowerCase('es-PE')}
            </p>
          </Link>
        ))}
      </div>
      <section className='corner-exit-m bg-secondary space-y-2 p-6'>
        <h2 className='text-lg font-semibold'>La operación diaria sigue en Apamuy Socios</h2>
        <p className='text-muted-foreground text-sm'>
          Los negocios y repartidores reciben, preparan y entregan sus pedidos desde la app. Los
          próximos módulos del panel son Marketing y Pedidos en vivo.
        </p>
      </section>
    </div>
  )
}
