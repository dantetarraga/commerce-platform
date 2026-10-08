import { Link } from '@tanstack/react-router'
import {
  BellRing,
  ChartColumn,
  CircleCheck,
  MapPinned,
  PauseCircle,
  Wallet,
  type LucideIcon,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { supportWhatsappUrl } from '@/lib/contact'

interface Point {
  icon: LucideIcon
  title: string
  body: string
}

const storePoints: Point[] = [
  {
    icon: BellRing,
    title: 'Pedidos al instante',
    body: 'Llegan con alarma a la app Apamuy Socios. Aceptas y dices en cuántos minutos está listo.',
  },
  {
    icon: PauseCircle,
    title: 'Tú decides cuándo',
    body: 'Pausa los pedidos cuando la cocina se llene y marca agotado lo que se acabó.',
  },
  {
    icon: ChartColumn,
    title: 'Tu día en números',
    body: 'Ventas por hora, cómo te pagaron y lo más pedido, sin sacar cuentas.',
  },
]

const courierPoints: Point[] = [
  {
    icon: CircleCheck,
    title: 'Tomas los pedidos que quieras',
    body: 'Te conectas cuando puedes y eliges entre los pedidos listos de tu ciudad.',
  },
  {
    icon: MapPinned,
    title: 'La ruta en tu celular',
    body: 'Un toque abre Google Maps con el camino al negocio y a la puerta del cliente.',
  },
  {
    icon: Wallet,
    title: 'Cobras al entregar',
    body: 'Registras cómo pagó el cliente y llevas la cuenta de tu día en la app.',
  },
]

function PointList({ points }: { points: Point[] }) {
  return (
    <ul className='space-y-5'>
      {points.map(({ icon: Icon, title, body }) => (
        <li key={title} className='flex gap-4'>
          <span className='bg-primary-soft text-primary corner-exit-s flex size-11 shrink-0 items-center justify-center'>
            <Icon className='size-5' aria-hidden />
          </span>
          <span className='space-y-1'>
            <span className='block font-semibold'>{title}</span>
            <span className='text-muted-foreground block'>{body}</span>
          </span>
        </li>
      ))}
    </ul>
  )
}

function JoinButton({ text, label }: { text: string; label: string }) {
  const url = supportWhatsappUrl(text)
  if (!url) return null
  return (
    <Button asChild size='lg'>
      <a href={url} target='_blank' rel='noreferrer'>
        {label}
      </a>
    </Button>
  )
}

export function ForPartners() {
  return (
    <>
      <section id='negocios' className='mx-auto max-w-6xl px-4 py-20 sm:px-6'>
        <div className='grid items-center gap-12 lg:grid-cols-2'>
          <div className='corner-exit-l relative aspect-[4/5] overflow-hidden sm:aspect-[4/3] lg:aspect-[4/5]'>
            <img
              src='/landing/grill.webp'
              alt='Platos recién servidos en la mesa de un restaurante'
              loading='lazy'
              decoding='async'
              className='size-full object-cover'
            />
          </div>
          <div className='space-y-8'>
            <div className='space-y-3'>
              <p className='text-primary text-sm font-semibold tracking-wider uppercase'>
                Para negocios
              </p>
              <h2 className='text-4xl font-bold text-balance'>
                Recibe pedidos sin contestar el teléfono
              </h2>
              <p className='text-muted-foreground text-lg'>
                Restaurantes, bodegas, boticas o lo que vendas: tu negocio aparece para todo Yauri.
              </p>
            </div>
            <PointList points={storePoints} />
            <div className='flex flex-wrap gap-3'>
              <JoinButton
                label='Quiero sumar mi negocio'
                text='Hola, quiero sumar mi negocio a Apamuy.'
              />
              <Button asChild size='lg' variant='outline'>
                <Link to='/login'>Ya soy socio · Ingresar</Link>
              </Button>
            </div>
          </div>
        </div>
      </section>

      <section id='repartidores' className='bg-foreground text-background'>
        <div className='mx-auto grid max-w-6xl gap-12 px-4 py-20 sm:px-6 lg:grid-cols-[1fr_1.1fr]'>
          <div className='space-y-4'>
            <p className='text-sm font-semibold tracking-wider uppercase opacity-70'>
              Para repartidores
            </p>
            <h2 className='text-4xl font-bold text-balance'>Reparte en tu ciudad, a tu ritmo</h2>
            <p className='text-lg opacity-75'>
              Con tu moto o bici, conectado solo cuando quieres. Todo desde la app Apamuy Socios.
            </p>
            <JoinButton label='Quiero repartir' text='Hola, quiero repartir con Apamuy.' />
          </div>
          <div className='[&_.text-muted-foreground]:text-background/70'>
            <PointList points={courierPoints} />
          </div>
        </div>
      </section>
    </>
  )
}
