import { Link, Outlet } from '@tanstack/react-router'
import { ArrowLeft, Bike, ShieldCheck, Store, type LucideIcon } from 'lucide-react'
import { BrandMark } from '@/components/layout/brand-mark'
import { ThemeToggle } from '@/components/layout/theme-toggle'

const audiences: { icon: LucideIcon; title: string; text: string }[] = [
  { icon: Store, title: 'Negocios', text: 'Pedidos en vivo, tu carta y las ventas del día.' },
  { icon: Bike, title: 'Repartidores', text: 'Tus entregas y tu caja, en la app Apamuy Socios.' },
  {
    icon: ShieldCheck,
    title: 'Equipo Apamuy',
    text: 'Socios, pedidos de la ciudad y la caja de todos.',
  },
]

function Brand({ className }: { className?: string }) {
  return (
    <Link to='/' className={className} aria-label='Apamuy, ir a la portada'>
      <span className='flex items-center gap-2.5'>
        <BrandMark className='size-9 text-xl' />
        <span className='font-display text-xl font-bold'>apamuy</span>
      </span>
    </Link>
  )
}

export function AuthLayout() {
  return (
    <div className='grid min-h-svh lg:grid-cols-[1fr_1.05fr]'>
      <aside className='relative hidden overflow-hidden lg:block'>
        <img src='/landing/table.webp' alt='' className='absolute inset-0 size-full object-cover' />
        <div
          aria-hidden
          className='from-ink/90 via-ink/60 to-ink/25 absolute inset-0 bg-linear-to-t'
        />
        <div className='text-ink-foreground relative flex h-full flex-col justify-between p-12'>
          <Brand />
          <div className='space-y-8'>
            <div className='space-y-4'>
              <p className='text-sm font-semibold tracking-wider uppercase opacity-80'>
                Socios y equipo Apamuy
              </p>
              <p className='font-display text-5xl leading-[1.02] font-bold text-balance xl:text-6xl'>
                Para quienes <span className='text-ink-accent'>mueven Yauri.</span>
              </p>
            </div>
            <ul className='space-y-4'>
              {audiences.map(({ icon: Icon, title, text }) => (
                <li key={title} className='flex items-start gap-3'>
                  <span className='bg-ink-foreground/15 corner-exit-s flex size-10 shrink-0 items-center justify-center'>
                    <Icon className='size-5' aria-hidden />
                  </span>
                  <span>
                    <span className='block text-lg font-semibold'>{title}</span>
                    <span className='block opacity-80'>{text}</span>
                  </span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </aside>

      <section className='flex flex-col'>
        <div className='flex items-center justify-between px-5 py-5 sm:px-8'>
          <Link
            to='/'
            className='text-muted-foreground hover:text-foreground inline-flex items-center gap-1.5 text-sm font-medium'
          >
            <ArrowLeft className='size-4' aria-hidden />
            Volver a la portada
          </Link>
          <div className='flex items-center gap-2'>
            <Brand className='lg:hidden' />
            <ThemeToggle />
          </div>
        </div>
        <div className='flex flex-1 items-start justify-center px-5 pt-10 pb-16 sm:px-8 lg:items-center lg:pt-6'>
          <div className='w-full max-w-sm'>
            <Outlet />
          </div>
        </div>
      </section>
    </div>
  )
}
