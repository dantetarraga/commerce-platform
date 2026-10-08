import { Link, Outlet } from '@tanstack/react-router'
import { ArrowLeft, BellRing, ChartColumn, UtensilsCrossed, type LucideIcon } from 'lucide-react'
import { BrandMark } from '@/components/layout/brand-mark'

const highlights: { icon: LucideIcon; text: string }[] = [
  { icon: BellRing, text: 'Pedidos en vivo, con alarma' },
  { icon: UtensilsCrossed, text: 'Tu carta y tus horarios al día' },
  { icon: ChartColumn, text: 'Las ventas de tu día, sin sacar cuentas' },
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
                Panel de Apamuy
              </p>
              <p className='font-display text-5xl leading-[1.02] font-bold text-balance xl:text-6xl'>
                Tu negocio, <span className='text-ink-accent'>al día.</span>
              </p>
            </div>
            <ul className='space-y-3'>
              {highlights.map(({ icon: Icon, text }) => (
                <li key={text} className='flex items-center gap-3 text-lg'>
                  <span className='bg-ink-foreground/15 corner-exit-s flex size-9 items-center justify-center'>
                    <Icon className='size-4.5' aria-hidden />
                  </span>
                  {text}
                </li>
              ))}
            </ul>
          </div>
          <p className='text-sm opacity-70'>
            Para el equipo de Apamuy y los negocios socios de Yauri.
          </p>
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
          <Brand className='lg:hidden' />
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
