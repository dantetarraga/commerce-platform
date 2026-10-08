import {
  Bike,
  Cake,
  Gift,
  Pill,
  ShoppingBasket,
  Store,
  UtensilsCrossed,
  Wine,
  type LucideIcon,
} from 'lucide-react'

const steps = [
  {
    title: 'Eliges',
    body: 'Mira qué está abierto cerca de ti, arma tu bolsa y confirma tu dirección en el mapa.',
  },
  {
    title: 'El negocio lo prepara',
    body: 'Te avisamos cuando lo acepta y cuánto le falta. Sin llamadas ni esperas a ciegas.',
  },
  {
    title: 'Te lo traen',
    body: 'Ves al repartidor en el mapa hasta tu puerta y pagas al recibir: efectivo, Yape o Plin.',
  },
]

const categories: { label: string; icon: LucideIcon }[] = [
  { label: 'Restaurantes', icon: UtensilsCrossed },
  { label: 'Bodegas', icon: Store },
  { label: 'Botica', icon: Pill },
  { label: 'Mercado', icon: ShoppingBasket },
  { label: 'Postres', icon: Cake },
  { label: 'Licores', icon: Wine },
  { label: 'Regalos', icon: Gift },
  { label: 'Encargos', icon: Bike },
]

export function HowItWorks() {
  return (
    <section id='como-funciona' className='bg-card border-y'>
      <div className='mx-auto max-w-6xl space-y-14 px-4 py-20 sm:px-6'>
        <div className='max-w-2xl space-y-3'>
          <h2 className='text-4xl font-bold text-balance'>Pedir es así de simple</h2>
          <p className='text-muted-foreground text-lg'>
            Hecho para Yauri: negocios de aquí, repartidores de aquí y precios en soles.
          </p>
        </div>

        <ol className='grid gap-6 md:grid-cols-3'>
          {steps.map((step, i) => (
            <li key={step.title} className='bg-background corner-exit-m space-y-3 border p-6'>
              <span className='bg-primary text-primary-foreground font-display corner-exit-s inline-flex size-10 items-center justify-center text-lg font-bold'>
                {i + 1}
              </span>
              <h3 className='text-xl font-semibold'>{step.title}</h3>
              <p className='text-muted-foreground'>{step.body}</p>
            </li>
          ))}
        </ol>

        <div className='space-y-4'>
          <h3 className='text-lg font-semibold'>Lo que encuentras</h3>
          <ul className='flex flex-wrap gap-2'>
            {categories.map(({ label, icon: Icon }) => (
              <li
                key={label}
                className='bg-secondary inline-flex items-center gap-2 rounded-full px-4 py-2 text-sm font-medium'
              >
                <Icon className='text-primary size-4' aria-hidden />
                {label}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  )
}
