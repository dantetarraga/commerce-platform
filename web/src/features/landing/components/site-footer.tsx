import { Link } from '@tanstack/react-router'
import { BrandMark } from '@/components/layout/brand-mark'

export function SiteFooter() {
  return (
    <footer className='border-t'>
      <div className='mx-auto flex max-w-6xl flex-col gap-6 px-4 py-10 sm:flex-row sm:items-center sm:justify-between sm:px-6'>
        <div className='flex items-center gap-2.5'>
          <BrandMark className='size-8 text-lg' />
          <span className='font-display text-lg font-bold'>apamuy</span>
          <span className='text-muted-foreground text-sm'>· Hecho en Espinar</span>
        </div>
        <nav aria-label='Pie de página' className='text-muted-foreground flex gap-6 text-sm'>
          <a href='#negocios' className='hover:text-foreground'>
            Negocios
          </a>
          <a href='#repartidores' className='hover:text-foreground'>
            Repartidores
          </a>
          <Link to='/login' className='hover:text-foreground'>
            Ingresar al panel
          </Link>
        </nav>
        <p className='text-muted-foreground text-sm'>© {new Date().getFullYear()} Apamuy</p>
      </div>
    </footer>
  )
}
