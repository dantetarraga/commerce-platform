import { ArrowRight, Smartphone } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { PhoneShot } from './phone-shot'

export function Hero() {
  return (
    <section id='inicio' className='relative overflow-hidden'>
      <div
        aria-hidden
        className='corner-exit-l bg-primary-soft absolute top-10 -right-40 h-[34rem] w-[42rem] max-w-none rotate-6 lg:-right-20'
      />
      <div className='relative mx-auto grid max-w-6xl items-center gap-12 px-4 pt-14 pb-20 sm:px-6 lg:grid-cols-[1.05fr_1fr] lg:pt-20 lg:pb-28'>
        <div className='space-y-7'>
          <p className='text-primary text-sm font-semibold tracking-wider uppercase'>
            Yauri · Espinar · Cusco
          </p>
          <h1 className='text-5xl leading-[0.95] font-bold text-balance sm:text-6xl lg:text-7xl'>
            Lo de tu barrio, <span className='text-primary'>en minutos.</span>
          </h1>
          <p className='text-muted-foreground max-w-xl text-lg text-pretty'>
            Pide comida, bodega, botica y encargos a los negocios de Yauri. Lo sigues en el mapa
            hasta tu puerta y pagas al recibir: efectivo, Yape o Plin.
          </p>
          <div className='flex flex-wrap items-center gap-3'>
            <span className='bg-foreground text-background corner-exit-s inline-flex h-12 items-center gap-3 px-5'>
              <Smartphone className='size-5' aria-hidden />
              <span className='leading-tight'>
                <span className='block text-xs opacity-75'>Muy pronto en</span>
                <span className='block text-sm font-semibold'>Google Play</span>
              </span>
            </span>
            <Button asChild size='lg' variant='outline'>
              <a href='#negocios'>
                Sumar mi negocio
                <ArrowRight aria-hidden />
              </a>
            </Button>
          </div>
        </div>

        <div className='relative mx-auto flex h-[30rem] w-full max-w-md justify-center sm:h-[34rem]'>
          <PhoneShot
            src='/landing/app-store.webp'
            alt='La app de Apamuy mostrando una picantería con su carta'
            className='absolute top-10 left-0 -rotate-6 opacity-95 sm:left-2'
          />
          <PhoneShot
            src='/landing/app-home.webp'
            alt='Inicio de la app de Apamuy con categorías y negocios abiertos'
            className='absolute top-0 right-0 rotate-3 sm:right-2'
          />
        </div>
      </div>
    </section>
  )
}
