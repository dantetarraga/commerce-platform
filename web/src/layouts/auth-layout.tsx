import { Outlet } from '@tanstack/react-router'
import { BrandMark } from '@/components/layout/brand-mark'

export function AuthLayout() {
  return (
    <div className='grid min-h-svh lg:grid-cols-[1.1fr_1fr]'>
      <section className='bg-primary-soft relative hidden overflow-hidden p-12 lg:flex lg:flex-col lg:justify-between'>
        <div className='flex items-center gap-3'>
          <BrandMark />
          <span className='font-display text-2xl font-bold'>Apamuy</span>
        </div>
        <div className='space-y-4'>
          <p className='font-display text-6xl leading-[0.95] font-bold'>
            Todo Yauri,
            <br />
            <span className='text-primary'>al toque.</span>
          </p>
          <p className='text-muted-foreground max-w-sm text-lg'>
            El panel del equipo Apamuy y de los negocios socios de Espinar.
          </p>
        </div>
        <div
          aria-hidden
          className='corner-exit-l bg-primary/10 pointer-events-none absolute -right-24 -bottom-24 size-96'
        />
        <p className='text-muted-foreground text-sm'>Apamuy · "tráelo" en quechua</p>
      </section>

      <section className='flex items-center justify-center px-5 py-12'>
        <div className='w-full max-w-sm'>
          <div className='mb-10 flex items-center gap-3 lg:hidden'>
            <BrandMark />
            <span className='font-display text-2xl font-bold'>Apamuy</span>
          </div>
          <Outlet />
        </div>
      </section>
    </div>
  )
}
